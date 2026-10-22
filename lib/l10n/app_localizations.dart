import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// This language's own name, shown in the language setting.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// Stands for the AI provider when its name is unknown.
  ///
  /// In en, this message translates to:
  /// **'AI provider'**
  String get errorProviderFallback;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Provider quota reached'**
  String get errorQuotaTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Your {provider} quota is used up for now.'**
  String errorQuotaBody(String provider);

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Post removed by moderators'**
  String get errorRemovedTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'This thread is no longer available on Reddit.'**
  String get errorRemovedBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'This subreddit is private'**
  String get errorPrivateTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Only its members can read this thread.'**
  String get errorPrivateBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Quarantined subreddit'**
  String get errorQuarantinedTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Reddit restricts access to this subreddit.'**
  String get errorQuarantinedBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Banned subreddit'**
  String get errorBannedTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'This subreddit no longer exists on Reddit.'**
  String get errorBannedBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'This post was deleted'**
  String get errorDeletedTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'There is nothing left to summarize.'**
  String get errorDeletedBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Thread not found'**
  String get errorNotFoundTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Reddit can\'t find this post. Check the link.'**
  String get errorNotFoundBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'This link isn\'t a thread'**
  String get errorUnsupportedUrlTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'TL;DR+ summarizes Reddit posts, not profiles or subreddits.'**
  String get errorUnsupportedUrlBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'This link isn\'t a Reddit thread'**
  String get errorInvalidUrlTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Share or paste a link to a Reddit post.'**
  String get errorInvalidUrlBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Nothing to summarize'**
  String get errorEmptyTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'This post has no text or usable comments.'**
  String get errorEmptyBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Your {provider} key was refused'**
  String errorKeyInvalidTitle(String provider);

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Check or replace your key in Settings.'**
  String get errorKeyInvalidBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'No {provider} key'**
  String errorKeyMissingTitle(String provider);

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Add your AI key to start a summary.'**
  String get errorKeyMissingBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Model unavailable'**
  String get errorModelUnavailableTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Pick another model in Settings.'**
  String get errorModelUnavailableBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'This is taking too long'**
  String get errorTimeoutTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'The summary didn\'t finish in time. Try again in a moment.'**
  String get errorTimeoutBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get errorNetworkTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection, then try again.'**
  String get errorNetworkBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'{provider} isn\'t responding'**
  String errorLlmUnavailableTitle(String provider);

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'The AI provider is unavailable for now.'**
  String get errorLlmUnavailableBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Unusable AI answer'**
  String get errorOutputInvalidTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'The AI returned an incomplete result. Try again.'**
  String get errorOutputInvalidBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Reddit is refusing access'**
  String get errorRedditBlockedTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Reddit is temporarily blocking this thread. Try again in a few minutes.'**
  String get errorRedditBlockedBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Reddit isn\'t responding'**
  String get errorRedditUnavailableTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Reddit is unavailable for now. Try again.'**
  String get errorRedditUnavailableBody;

  /// Error title.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// Error body.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get errorGenericBody;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'joy'**
  String get emotionJoy;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'sadness'**
  String get emotionSadness;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'anger'**
  String get emotionAnger;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'fear'**
  String get emotionFear;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'disgust'**
  String get emotionDisgust;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'surprise'**
  String get emotionSurprise;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'love'**
  String get emotionLove;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'pride'**
  String get emotionPride;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'relief'**
  String get emotionRelief;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'hope'**
  String get emotionHope;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'excitement'**
  String get emotionExcitement;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'envy'**
  String get emotionEnvy;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'guilt'**
  String get emotionGuilt;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'shame'**
  String get emotionShame;

  /// Emotion.
  ///
  /// In en, this message translates to:
  /// **'neutral'**
  String get emotionNeutral;

  /// Sentiment.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get sentimentPositive;

  /// Sentiment.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get sentimentNegative;

  /// Sentiment.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get sentimentNeutral;

  /// Toxicity level.
  ///
  /// In en, this message translates to:
  /// **'Low toxicity'**
  String get toxicityLow;

  /// Toxicity level.
  ///
  /// In en, this message translates to:
  /// **'Moderate toxicity'**
  String get toxicityModerate;

  /// Toxicity level.
  ///
  /// In en, this message translates to:
  /// **'High toxicity'**
  String get toxicityHigh;

  /// Toxicity unknown.
  ///
  /// In en, this message translates to:
  /// **'Toxicity —'**
  String get toxicityUnknown;

  /// Under a minute ago.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get relativeJustNow;

  /// Minutes ago.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String relativeMinutes(String count);

  /// Hours ago, same day.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String relativeHours(String count);

  /// The day before.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get relativeYesterday;

  /// 2 to 6 calendar days ago.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String relativeDays(String count);

  /// intl DateFormat pattern for a date this year.
  ///
  /// In en, this message translates to:
  /// **'MMM d'**
  String get dateShortPattern;

  /// intl DateFormat pattern for a date in another year.
  ///
  /// In en, this message translates to:
  /// **'MMM d, y'**
  String get dateLongPattern;

  /// A rounded percentage.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentValue(String value);

  /// Screen reader label of the NSFW badge.
  ///
  /// In en, this message translates to:
  /// **'Adult content'**
  String get commonAdultContent;

  /// Snackbar when a shared link is not a thread.
  ///
  /// In en, this message translates to:
  /// **'This link isn\'t a Reddit thread'**
  String get appNotAThread;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Summary ready'**
  String get appSummaryReady;

  /// Snackbar action.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get appView;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'The summary failed'**
  String get appSummaryFailed;

  /// Snackbar action.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get appDetails;

  /// Field error.
  ///
  /// In en, this message translates to:
  /// **'This link isn\'t a Reddit thread'**
  String get homeNotAThread;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'The clipboard is empty'**
  String get homeClipboardEmpty;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Summary deleted'**
  String get homeSummaryDeleted;

  /// Snackbar action.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get homeUndo;

  /// Menu item.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get homeShare;

  /// Menu item and screen reader action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get homeDelete;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// History header.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get homeRecent;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Paste a link'**
  String get homePasteLink;

  /// URL field hint.
  ///
  /// In en, this message translates to:
  /// **'Paste a Reddit link'**
  String get homeUrlHint;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Summarize'**
  String get homeSummarize;

  /// Banner.
  ///
  /// In en, this message translates to:
  /// **'Add your AI key to get started'**
  String get homeAddKey;

  /// Screen reader label of a history row's sentiment.
  ///
  /// In en, this message translates to:
  /// **'Sentiment {sentiment}'**
  String homeSentiment(String sentiment);

  /// Empty history title.
  ///
  /// In en, this message translates to:
  /// **'Summarize a thread in 3 steps'**
  String get homeEmptyTitle;

  /// Empty history step.
  ///
  /// In en, this message translates to:
  /// **'In Reddit, open a post'**
  String get homeEmptyStep1;

  /// Empty history step.
  ///
  /// In en, this message translates to:
  /// **'Tap Share'**
  String get homeEmptyStep2;

  /// Empty history step.
  ///
  /// In en, this message translates to:
  /// **'Choose TL;DR+'**
  String get homeEmptyStep3;

  /// iOS hint.
  ///
  /// In en, this message translates to:
  /// **'Not in the list? Tap “More” and turn on TL;DR+.'**
  String get homeEmptyIosHint;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'See an example'**
  String get homeSeeExample;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Model {from} unavailable, {to} used instead.'**
  String settingsModelFallback(String from, String to);

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Clear history?'**
  String get settingsClearTitle;

  /// Dialog body.
  ///
  /// In en, this message translates to:
  /// **'All summaries saved on this phone will be deleted.'**
  String get settingsClearBody;

  /// Dialog action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// Dialog action.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsClear;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'History cleared'**
  String get settingsCleared;

  /// Screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'AI provider'**
  String get settingsProvider;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsModel;

  /// Setting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language choice: follow the device.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get settingsDeviceLanguage;

  /// Setting.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get settingsClearHistory;

  /// App version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// Privacy note.
  ///
  /// In en, this message translates to:
  /// **'Your key is stored only on this phone and is sent only to your AI provider.'**
  String get keyFormPrivacy;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get keyFormSave;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete the {provider} key?'**
  String keyFormDeleteTitle(String provider);

  /// Dialog action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get keyFormCancel;

  /// Dialog action.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get keyFormDelete;

  /// Result.
  ///
  /// In en, this message translates to:
  /// **'✓ Valid key'**
  String get keyFormValid;

  /// Result.
  ///
  /// In en, this message translates to:
  /// **'✗ Key refused by {provider}'**
  String keyFormRefused(String provider);

  /// Result.
  ///
  /// In en, this message translates to:
  /// **'Saved, not verified'**
  String get keyFormUnverified;

  /// Result.
  ///
  /// In en, this message translates to:
  /// **'Paste your key before saving'**
  String get keyFormEmpty;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'{provider} API key'**
  String keyFormLabel(String provider);

  /// Field hint.
  ///
  /// In en, this message translates to:
  /// **'Paste your key here'**
  String get keyFormHint;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Show key'**
  String get keyFormShow;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide key'**
  String get keyFormHide;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get keyFormDeleteKey;

  /// Hint.
  ///
  /// In en, this message translates to:
  /// **'This doesn\'t look like a {provider} key.'**
  String keyFormPatternMismatch(String provider);

  /// Link.
  ///
  /// In en, this message translates to:
  /// **'Get a {provider} key'**
  String keyFormGetKey(String provider);

  /// Provider subtitle.
  ///
  /// In en, this message translates to:
  /// **'Free tier available'**
  String get setupGeminiSubtitle;

  /// Provider subtitle.
  ///
  /// In en, this message translates to:
  /// **'Claude, by Anthropic'**
  String get setupAnthropicSubtitle;

  /// Provider subtitle.
  ///
  /// In en, this message translates to:
  /// **'GPT, by OpenAI'**
  String get setupOpenaiSubtitle;

  /// Step.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get setupStep1;

  /// Pitch.
  ///
  /// In en, this message translates to:
  /// **'Summarize any Reddit thread with your own AI.'**
  String get setupPitch;

  /// Section.
  ///
  /// In en, this message translates to:
  /// **'Choose your provider'**
  String get setupChooseProvider;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setupContinue;

  /// Step.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2'**
  String get setupStep2;

  /// Title.
  ///
  /// In en, this message translates to:
  /// **'Paste your {provider} key'**
  String setupPasteKey(String provider);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get setupVerify;

  /// Success.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set ✓'**
  String get setupDone;

  /// Screen reader label of the verdict line.
  ///
  /// In en, this message translates to:
  /// **'Sentiment {sentiment}. Emotions: {emotions}. {toxicity}.'**
  String summaryVerdictSemantics(
    String sentiment,
    String emotions,
    String toxicity,
  );

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Read less'**
  String get summaryReadLess;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get summaryReadMore;

  /// Loading step.
  ///
  /// In en, this message translates to:
  /// **'Fetching the thread…'**
  String get summaryFetchingStep;

  /// Loading step.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing…'**
  String get summaryAnalyzingStep;

  /// Screen reader label.
  ///
  /// In en, this message translates to:
  /// **'Summary in progress'**
  String get summaryInProgress;

  /// Loading header.
  ///
  /// In en, this message translates to:
  /// **'Reddit thread'**
  String get summaryRedditThread;

  /// Loading hint.
  ///
  /// In en, this message translates to:
  /// **'Long threads can take up to 30 s.'**
  String get summaryLongWait;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get summaryCancel;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get summaryOpenSettings;

  /// Countdown button.
  ///
  /// In en, this message translates to:
  /// **'Try again in {time}'**
  String summaryRetryIn(String time);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get summaryRetry;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get summaryBackHome;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Model unavailable: the default model was used.'**
  String get summaryModelFallback;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Regenerate this summary?'**
  String get summaryRegenerateTitle;

  /// Dialog body.
  ///
  /// In en, this message translates to:
  /// **'The French translation will be deleted.'**
  String get summaryRegenerateBody;

  /// Action.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get summaryRegenerate;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Reddit'**
  String get summaryCannotOpenReddit;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Share summary'**
  String get summaryShare;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Open in Reddit'**
  String get summaryOpenInReddit;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get summaryMoreOptions;

  /// Screen reader label.
  ///
  /// In en, this message translates to:
  /// **'AI analysis in progress'**
  String get summaryAnalyzingSemantics;

  /// Screen reader label.
  ///
  /// In en, this message translates to:
  /// **'Fetching the thread'**
  String get summaryFetchingSemantics;

  /// Banner.
  ///
  /// In en, this message translates to:
  /// **'Example: this summary doesn\'t use your key and isn\'t saved.'**
  String get summaryDemoBanner;

  /// Banner action.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get summaryClose;

  /// Banner; date is relative (2 days ago) or summaryBannerOnDate.
  ///
  /// In en, this message translates to:
  /// **'Already summarized {date}'**
  String summaryAlreadySummarized(String date);

  /// An absolute date in the banner.
  ///
  /// In en, this message translates to:
  /// **'on {date}'**
  String summaryBannerOnDate(String date);

  /// Section.
  ///
  /// In en, this message translates to:
  /// **'In short'**
  String get summaryInShort;

  /// Section.
  ///
  /// In en, this message translates to:
  /// **'Viewpoints'**
  String get summaryViewpoints;

  /// Thread stats.
  ///
  /// In en, this message translates to:
  /// **'{score} points · {percent} upvoted · {comments} comments'**
  String summaryStats(String score, String percent, String comments);

  /// Footer.
  ///
  /// In en, this message translates to:
  /// **'{analyzed} of {total} comments analyzed · {model}'**
  String summaryCommentsAnalyzed(String analyzed, String total, String model);

  /// Section.
  ///
  /// In en, this message translates to:
  /// **'The AI\'s take'**
  String get summaryAiTake;

  /// Button (French app only).
  ///
  /// In en, this message translates to:
  /// **'Translate to French'**
  String get summaryTranslateToFrench;

  /// Segment: original language.
  ///
  /// In en, this message translates to:
  /// **'Original ({code})'**
  String summaryOriginal(String code);

  /// Segment: French translation.
  ///
  /// In en, this message translates to:
  /// **'FR'**
  String get summaryFrench;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
