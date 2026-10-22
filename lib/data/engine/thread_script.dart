/// The script [RedditPage] runs in the thread page to read it.
///
/// Reddit now refuses every anonymous `.json` request, even from a browser
/// that passed its JavaScript check ("blocked by network security"), so the
/// thread is read from the page itself: the post and the first comments as
/// the page shows them (Reddit only renders the comment tree for a real
/// navigation, not for a `fetch`), then the « more comments » blocks it leaves
/// for later (`/svc/shreddit/more-comments`, one POST each), shallowest first,
/// the way the page fills them in when they are tapped or scrolled to.
///
/// The script answers on [channel] with `{nonce, status, text}`, where `text`
/// is the thread in the `[postListing, commentListing]` shape of Reddit's
/// `.json`, so the rest of the engine reads it as before. Status 0 means « not
/// ready yet, try again »: the page is still Reddit's check, or a request failed.
String threadScript({
  required String channel,
  required String nonce,
  int maxComments = 500,
  int maxDepth = 4,
  int maxRequests = 60,
  int budgetMs = 10000,
}) =>
    '''
(async () => {
  const send = (status, text) =>
    $channel.postMessage(JSON.stringify({nonce: "$nonce", status, text}));
  try {
    if (document.readyState !== "complete") return send(0, "");
    const post = document.querySelector("shreddit-post");
    if (!post) {
      // Reddit's check, or an error page: its status says which.
      if (!location.protocol.startsWith("http")) return send(0, "");
      const r = await fetch(location.href, {credentials: "include"});
      const t = await r.text();
      if (r.status === 404) return send(404, '{"error":404}');
      if (r.status === 403 && !/network security/i.test(t)) {
        return send(403, '{"error":403,"reason":"private"}');
      }
      return send(r.status === 403 ? 403 : 0, "");
    }

    const start = Date.now();
    const parse = (html) => new DOMParser().parseFromString(html, "text/html");
    const id = (post.getAttribute("id") || "").replace(/^t3_/, "");
    const sub = post.getAttribute("subreddit-name");
    const permalink = post.getAttribute("permalink") || "/r/" + sub + "/comments/" + id + "/";
    // An inert copy, filled in without touching the page's own scripts.
    const doc = parse(document.documentElement.outerHTML);
    const top = doc.querySelector("shreddit-post") || post;

    const csrf = (document.cookie.match(/(?:^|; )csrf_token=([^;]+)/) || [])[1] || "";
    const depthOf = (p) => +(new URL(p.getAttribute("src"), location.href)
      .searchParams.get("startingDepth") || 0);
    let requests = 0;
    for (;;) {
      if (requests >= $maxRequests || Date.now() - start > $budgetMs) break;
      if (doc.querySelectorAll("shreddit-comment").length >= $maxComments) break;
      const more = [...doc.querySelectorAll("faceplate-partial[method=post]")]
        .filter((p) => /more-comments/.test(p.getAttribute("src")) && depthOf(p) <= $maxDepth)
        .sort((a, b) => depthOf(a) - depthOf(b))
        .slice(0, Math.min(6, $maxRequests - requests));
      if (more.length === 0) break;
      requests += more.length;
      await Promise.all(more.map(async (p) => {
        const form = new URLSearchParams();
        p.querySelectorAll("input[type=hidden]").forEach((i) => form.append(i.name, i.value));
        form.append("csrf_token", csrf);
        try {
          const res = await fetch(p.getAttribute("src"), {method: "POST", credentials: "include",
            headers: {"content-type": "application/x-www-form-urlencoded"}, body: form});
          if (!res.ok) throw new Error(String(res.status));
          const part = parse(await res.text());
          p.replaceWith(...[...part.body.childNodes].map((n) => doc.importNode(n, true)));
        } catch (_) {
          p.remove();
        }
      }));
    }

    // Text with its paragraphs, list items and line breaks.
    const blocks = /^(P|DIV|LI|BLOCKQUOTE|PRE|H[1-6]|UL|OL|TABLE|TR)\$/;
    const textOf = (el) => {
      let out = "";
      const walk = (n, pre) => {
        if (n.nodeType === 3) { out += pre ? n.nodeValue : n.nodeValue.replace(/\\s+/g, " "); return; }
        if (n.nodeType !== 1) return;
        if (n.tagName === "BR") { out += "\\n"; return; }
        const block = blocks.test(n.tagName);
        if (block) out += "\\n";
        if (n.tagName === "LI") out += "- ";
        n.childNodes.forEach((c) => walk(c, pre || n.tagName === "PRE"));
        if (block) out += n.tagName === "P" ? "\\n\\n" : "\\n";
      };
      walk(el, false);
      return out.replace(/[ \\t]+\\n/g, "\\n").replace(/\\n[ \\t]+/g, "\\n")
        .replace(/\\n{3,}/g, "\\n\\n").trim();
    };
    const number = (value, fallback) => {
      const n = parseFloat(value);
      return Number.isFinite(n) ? n : fallback;
    };

    // Each comment's replies are the comments nested in its element.
    const all = [...doc.querySelectorAll("shreddit-comment")];
    const parentOf = (c) => (c.parentElement && c.parentElement.closest("shreddit-comment")) || null;
    const children = new Map();
    for (const c of all) {
      const parent = parentOf(c);
      if (!children.has(parent)) children.set(parent, []);
      children.get(parent).push(c);
    }
    const comment = (c) => {
      const replies = children.get(c) || [];
      const body = [...c.querySelectorAll("[slot=comment]")]
        .find((b) => b.closest("shreddit-comment") === c);
      return {kind: "t1", data: {
        id: (c.getAttribute("thingid") || "").replace(/^t1_/, ""),
        author: c.getAttribute("author") || "[deleted]",
        score: Math.round(number(c.getAttribute("score"), 0)),
        body: body ? textOf(body) : "",
        replies: replies.length === 0 ? "" :
          {kind: "Listing", data: {children: replies.map(comment)}},
      }};
    };

    const state = (top.getAttribute("item-state") || "").toLowerCase();
    const body = top.querySelector("[slot=text-body]");
    const created = Date.parse(top.getAttribute("created-timestamp") || "");
    const thread = {
      id, subreddit: sub, permalink,
      title: top.getAttribute("post-title") || "",
      author: top.getAttribute("author") || "[deleted]",
      created_utc: Number.isFinite(created) ? created / 1000 : Date.now() / 1000,
      score: Math.round(number(top.getAttribute("score"), 0)),
      upvote_ratio: number(top.getAttribute("upvote-ratio"), 1),
      num_comments: Math.round(number(top.getAttribute("comment-count"), all.length)),
      over_18: top.hasAttribute("nsfw"),
      selftext: body ? textOf(body) : "",
      removed_by_category: state.includes("deleted") ? "deleted" :
        state.includes("removed") ? "moderator" : null,
    };
    send(200, JSON.stringify([
      {kind: "Listing", data: {children: [{kind: "t3", data: thread}]}},
      {kind: "Listing", data: {children: (children.get(null) || []).map(comment)}},
    ]));
  } catch (_) {
    send(0, "");
  }
})();
''';
