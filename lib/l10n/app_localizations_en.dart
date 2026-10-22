// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get errorProviderFallback => 'AI provider';

  @override
  String get errorQuotaTitle => 'Provider quota reached';

  @override
  String errorQuotaBody(String provider) {
    return 'Your $provider quota is used up for now.';
  }

  @override
  String get errorRemovedTitle => 'Post removed by moderators';

  @override
  String get errorRemovedBody =>
      'This thread is no longer available on Reddit.';

  @override
  String get errorPrivateTitle => 'This subreddit is private';

  @override
  String get errorPrivateBody => 'Only its members can read this thread.';

  @override
  String get errorQuarantinedTitle => 'Quarantined subreddit';

  @override
  String get errorQuarantinedBody =>
      'Reddit restricts access to this subreddit.';

  @override
  String get errorBannedTitle => 'Banned subreddit';

  @override
  String get errorBannedBody => 'This subreddit no longer exists on Reddit.';

  @override
  String get errorDeletedTitle => 'This post was deleted';

  @override
  String get errorDeletedBody => 'There is nothing left to summarize.';

  @override
  String get errorNotFoundTitle => 'Thread not found';

  @override
  String get errorNotFoundBody =>
      'Reddit can\'t find this post. Check the link.';

  @override
  String get errorUnsupportedUrlTitle => 'This link isn\'t a thread';

  @override
  String get errorUnsupportedUrlBody =>
      'TL;DR+ summarizes Reddit posts, not profiles or subreddits.';

  @override
  String get errorInvalidUrlTitle => 'This link isn\'t a Reddit thread';

  @override
  String get errorInvalidUrlBody => 'Share or paste a link to a Reddit post.';

  @override
  String get errorEmptyTitle => 'Nothing to summarize';

  @override
  String get errorEmptyBody => 'This post has no text or usable comments.';

  @override
  String errorKeyInvalidTitle(String provider) {
    return 'Your $provider key was refused';
  }

  @override
  String get errorKeyInvalidBody => 'Check or replace your key in Settings.';

  @override
  String errorKeyMissingTitle(String provider) {
    return 'No $provider key';
  }

  @override
  String get errorKeyMissingBody => 'Add your AI key to start a summary.';

  @override
  String get errorModelUnavailableTitle => 'Model unavailable';

  @override
  String get errorModelUnavailableBody => 'Pick another model in Settings.';

  @override
  String get errorTimeoutTitle => 'This is taking too long';

  @override
  String get errorTimeoutBody =>
      'The summary didn\'t finish in time. Try again in a moment.';

  @override
  String get errorNetworkTitle => 'No connection';

  @override
  String get errorNetworkBody =>
      'Check your internet connection, then try again.';

  @override
  String errorLlmUnavailableTitle(String provider) {
    return '$provider isn\'t responding';
  }

  @override
  String get errorLlmUnavailableBody =>
      'The AI provider is unavailable for now.';

  @override
  String get errorOutputInvalidTitle => 'Unusable AI answer';

  @override
  String get errorOutputInvalidBody =>
      'The AI returned an incomplete result. Try again.';

  @override
  String get errorRedditBlockedTitle => 'Reddit is refusing access';

  @override
  String get errorRedditBlockedBody =>
      'Reddit is temporarily blocking this thread. Try again in a few minutes.';

  @override
  String get errorRedditUnavailableTitle => 'Reddit isn\'t responding';

  @override
  String get errorRedditUnavailableBody =>
      'Reddit is unavailable for now. Try again.';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericBody => 'Try again in a moment.';

  @override
  String get emotionJoy => 'joy';

  @override
  String get emotionSadness => 'sadness';

  @override
  String get emotionAnger => 'anger';

  @override
  String get emotionFear => 'fear';

  @override
  String get emotionDisgust => 'disgust';

  @override
  String get emotionSurprise => 'surprise';

  @override
  String get emotionLove => 'love';

  @override
  String get emotionPride => 'pride';

  @override
  String get emotionRelief => 'relief';

  @override
  String get emotionHope => 'hope';

  @override
  String get emotionExcitement => 'excitement';

  @override
  String get emotionEnvy => 'envy';

  @override
  String get emotionGuilt => 'guilt';

  @override
  String get emotionShame => 'shame';

  @override
  String get emotionNeutral => 'neutral';

  @override
  String get sentimentPositive => 'Positive';

  @override
  String get sentimentNegative => 'Negative';

  @override
  String get sentimentNeutral => 'Neutral';

  @override
  String get toxicityLow => 'Low toxicity';

  @override
  String get toxicityModerate => 'Moderate toxicity';

  @override
  String get toxicityHigh => 'High toxicity';

  @override
  String get toxicityUnknown => 'Toxicity —';

  @override
  String get relativeJustNow => 'just now';

  @override
  String relativeMinutes(String count) {
    return '$count min ago';
  }

  @override
  String relativeHours(String count) {
    return '${count}h ago';
  }

  @override
  String get relativeYesterday => 'yesterday';

  @override
  String relativeDays(String count) {
    return '$count days ago';
  }

  @override
  String get dateShortPattern => 'MMM d';

  @override
  String get dateLongPattern => 'MMM d, y';

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get commonAdultContent => 'Adult content';

  @override
  String get appNotAThread => 'This link isn\'t a Reddit thread';

  @override
  String get appSummaryReady => 'Summary ready';

  @override
  String get appView => 'View';

  @override
  String get appSummaryFailed => 'The summary failed';

  @override
  String get appDetails => 'Details';

  @override
  String get homeNotAThread => 'This link isn\'t a Reddit thread';

  @override
  String get homeClipboardEmpty => 'The clipboard is empty';

  @override
  String get homeSummaryDeleted => 'Summary deleted';

  @override
  String get homeUndo => 'Undo';

  @override
  String get homeShare => 'Share';

  @override
  String get homeDelete => 'Delete';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeRecent => 'Recent';

  @override
  String get homePasteLink => 'Paste a link';

  @override
  String get homeUrlHint => 'Paste a Reddit link';

  @override
  String get homeSummarize => 'Summarize';

  @override
  String get homeAddKey => 'Add your AI key to get started';

  @override
  String homeSentiment(String sentiment) {
    return 'Sentiment $sentiment';
  }

  @override
  String get homeEmptyTitle => 'Summarize a thread in 3 steps';

  @override
  String get homeEmptyStep1 => 'In Reddit, open a post';

  @override
  String get homeEmptyStep2 => 'Tap Share';

  @override
  String get homeEmptyStep3 => 'Choose TL;DR+';

  @override
  String get homeEmptyIosHint =>
      'Not in the list? Tap “More” and turn on TL;DR+.';

  @override
  String get homeSeeExample => 'See an example';

  @override
  String settingsModelFallback(String from, String to) {
    return 'Model $from unavailable, $to used instead.';
  }

  @override
  String get settingsClearTitle => 'Clear history?';

  @override
  String get settingsClearBody =>
      'All summaries saved on this phone will be deleted.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get settingsClear => 'Clear';

  @override
  String get settingsCleared => 'History cleared';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProvider => 'AI provider';

  @override
  String get settingsModel => 'Model';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsDeviceLanguage => 'Device language';

  @override
  String get settingsClearHistory => 'Clear history';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get keyFormPrivacy =>
      'Your key is stored only on this phone and is sent only to your AI provider.';

  @override
  String get keyFormSave => 'Save';

  @override
  String keyFormDeleteTitle(String provider) {
    return 'Delete the $provider key?';
  }

  @override
  String get keyFormCancel => 'Cancel';

  @override
  String get keyFormDelete => 'Delete';

  @override
  String get keyFormValid => '✓ Valid key';

  @override
  String keyFormRefused(String provider) {
    return '✗ Key refused by $provider';
  }

  @override
  String get keyFormUnverified => 'Saved, not verified';

  @override
  String get keyFormEmpty => 'Paste your key before saving';

  @override
  String keyFormLabel(String provider) {
    return '$provider API key';
  }

  @override
  String get keyFormHint => 'Paste your key here';

  @override
  String get keyFormShow => 'Show key';

  @override
  String get keyFormHide => 'Hide key';

  @override
  String get keyFormDeleteKey => 'Delete key';

  @override
  String keyFormPatternMismatch(String provider) {
    return 'This doesn\'t look like a $provider key.';
  }

  @override
  String keyFormGetKey(String provider) {
    return 'Get a $provider key';
  }

  @override
  String get setupGeminiSubtitle => 'Free tier available';

  @override
  String get setupAnthropicSubtitle => 'Claude, by Anthropic';

  @override
  String get setupOpenaiSubtitle => 'GPT, by OpenAI';

  @override
  String get setupStep1 => 'Step 1 of 2';

  @override
  String get setupPitch => 'Summarize any Reddit thread with your own AI.';

  @override
  String get setupChooseProvider => 'Choose your provider';

  @override
  String get setupContinue => 'Continue';

  @override
  String get setupStep2 => 'Step 2 of 2';

  @override
  String setupPasteKey(String provider) {
    return 'Paste your $provider key';
  }

  @override
  String get setupVerify => 'Verify';

  @override
  String get setupDone => 'You\'re all set ✓';

  @override
  String summaryVerdictSemantics(
    String sentiment,
    String emotions,
    String toxicity,
  ) {
    return 'Sentiment $sentiment. Emotions: $emotions. $toxicity.';
  }

  @override
  String get summaryReadLess => 'Read less';

  @override
  String get summaryReadMore => 'Read more';

  @override
  String get summaryFetchingStep => 'Fetching the thread…';

  @override
  String get summaryAnalyzingStep => 'AI is analyzing…';

  @override
  String get summaryInProgress => 'Summary in progress';

  @override
  String get summaryRedditThread => 'Reddit thread';

  @override
  String get summaryLongWait => 'Long threads can take up to 30 s.';

  @override
  String get summaryCancel => 'Cancel';

  @override
  String get summaryOpenSettings => 'Open Settings';

  @override
  String summaryRetryIn(String time) {
    return 'Try again in $time';
  }

  @override
  String get summaryRetry => 'Try again';

  @override
  String get summaryBackHome => 'Back to home';

  @override
  String get summaryModelFallback =>
      'Model unavailable: the default model was used.';

  @override
  String get summaryRegenerateTitle => 'Regenerate this summary?';

  @override
  String get summaryRegenerateBody => 'The French translation will be deleted.';

  @override
  String get summaryRegenerate => 'Regenerate';

  @override
  String get summaryCannotOpenReddit => 'Couldn\'t open Reddit';

  @override
  String get summaryShare => 'Share summary';

  @override
  String get summaryOpenInReddit => 'Open in Reddit';

  @override
  String get summaryMoreOptions => 'More options';

  @override
  String get summaryAnalyzingSemantics => 'AI analysis in progress';

  @override
  String get summaryFetchingSemantics => 'Fetching the thread';

  @override
  String get summaryDemoBanner =>
      'Example: this summary doesn\'t use your key and isn\'t saved.';

  @override
  String get summaryClose => 'Close';

  @override
  String summaryAlreadySummarized(String date) {
    return 'Already summarized $date';
  }

  @override
  String summaryBannerOnDate(String date) {
    return 'on $date';
  }

  @override
  String get summaryInShort => 'In short';

  @override
  String get summaryViewpoints => 'Viewpoints';

  @override
  String summaryStats(
    int scoreCount,
    String score,
    String percent,
    int commentCount,
    String comments,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      scoreCount,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    String _temp1 = intl.Intl.pluralLogic(
      commentCount,
      locale: localeName,
      other: '$comments comments',
      one: '$comments comment',
    );
    return '$_temp0 · $percent upvoted · $_temp1';
  }

  @override
  String summaryCommentsAnalyzed(String analyzed, String total, String model) {
    return '$analyzed of $total comments analyzed · $model';
  }

  @override
  String get summaryAiTake => 'The AI\'s take';

  @override
  String get summaryTranslateToFrench => 'Translate to French';

  @override
  String summaryOriginal(String code) {
    return 'Original ($code)';
  }

  @override
  String get summaryFrench => 'FR';
}
