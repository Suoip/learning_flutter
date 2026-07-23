/// Distinguishes SmartAcademy hub entries that have an associated video from
/// text-only, forum-style entries.
enum SmartAcademyEntryKind { video, forum }

/// A single hub entry - a placeholder video or a forum post. Static sample
/// data only for now; no backend yet.
class SmartAcademyEntry {
  const SmartAcademyEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.authorName,
    required this.description,
    this.durationLabel,
  });

  final String id;
  final SmartAcademyEntryKind kind;
  final String title;
  final String authorName;
  final String description;

  /// Video-only, e.g. "12:34". Null for forum entries.
  final String? durationLabel;
}

const List<SmartAcademyEntry> sampleVideoEntries = [
  SmartAcademyEntry(
    id: 'v1',
    kind: SmartAcademyEntryKind.video,
    title: 'Dart Null Safety in 12 Minutes',
    authorName: 'Priya Raman',
    durationLabel: '12:34',
    description:
        'Null safety is the single biggest change Dart ever shipped, and it '
        'trips up almost every developer coming from JavaScript or old-style '
        'Dart. In this video we walk through the difference between nullable '
        'and non-nullable types, why the compiler suddenly starts flagging '
        'your old code, and how the ?, !, and ?? operators actually work '
        'rather than just "the trick that makes the red squiggly line go '
        'away."\n\n'
        'We refactor a small, deliberately unsafe todo-list app step by '
        'step: adding proper nullable fields, using late correctly (and the '
        'one case where it bites you), and writing null-safe constructors '
        'with named parameters. By the end you will be able to read any '
        'null-safety error and know exactly what Dart is asking you to '
        'prove, instead of sprinkling ! everywhere until it compiles.',
  ),
  SmartAcademyEntry(
    id: 'v2',
    kind: SmartAcademyEntryKind.video,
    title: 'Flutter Layouts: Row, Column, and the Box Model',
    authorName: 'Diego Fuentes',
    durationLabel: '18:07',
    description:
        'Every Flutter beginner hits the same wall: a RenderFlex overflowed '
        'error shows up, and it is not obvious why. This video builds up '
        'Flutter\'s layout model from first principles - constraints go '
        'down, sizes go up, position is set by the parent - using nothing '
        'but Row, Column, Expanded, and Flexible, so the mental model sticks '
        'instead of just memorizing fixes.\n\n'
        'We build a responsive profile card from scratch, breaking it on '
        'purpose at each step to see exactly which constraint was violated '
        'and why. You will come away knowing when to reach for Expanded vs '
        'Flexible vs a plain SizedBox, and how to read an overflow error '
        'well enough to fix it in seconds instead of guessing.',
  ),
  SmartAcademyEntry(
    id: 'v3',
    kind: SmartAcademyEntryKind.video,
    title: 'State Management Showdown: setState vs Provider vs Riverpod',
    authorName: 'Amara Chukwu',
    durationLabel: '24:51',
    description:
        'State management is the question every Flutter developer asks '
        'eventually, and the honest answer is "it depends" - but that is '
        'not a satisfying answer without seeing the tradeoffs side by side. '
        'This video builds the exact same small counter-and-cart app three '
        'times: once with plain setState, once with Provider, and once with '
        'Riverpod, so you can compare the real code rather than opinions '
        'about it.\n\n'
        'We talk through what each approach actually solves - widget '
        'rebuild scope, testability, and how state survives navigation - '
        'and where each one starts to strain as the app grows. No '
        'recommendation is handed to you; instead you will have a concrete '
        'basis for picking the right tool for your own project\'s size and '
        'team.',
  ),
  SmartAcademyEntry(
    id: 'v4',
    kind: SmartAcademyEntryKind.video,
    title: "Building a REST API with Dart's shelf Package",
    authorName: 'Tom Whitfield',
    durationLabel: '15:42',
    description:
        'Dart is not just for Flutter frontends - shelf makes it a genuinely '
        'pleasant choice for small backend services too, and reusing one '
        'language across your client and server cuts a lot of context '
        'switching. This video sets up a shelf server from an empty folder, '
        'adds routing with shelf_router, and wires up JSON request/response '
        'handling for a simple notes API.\n\n'
        'We cover middleware (logging and CORS), returning proper HTTP '
        'status codes instead of always 200, and a basic error-handling '
        'pattern that keeps handlers readable. By the end you will have a '
        'working API you can point a Flutter app at, and a template you can '
        'reuse for your own backend experiments.',
  ),
  SmartAcademyEntry(
    id: 'v5',
    kind: SmartAcademyEntryKind.video,
    title: 'Async/Await Deep Dive: Futures, Streams, and Isolates',
    authorName: 'Priya Raman',
    durationLabel: '21:15',
    description:
        'async/await reads simply, but what is actually happening under the '
        'hood trips people up the first time they hit a bug involving '
        'timing. This video starts from what a Future really is (a promise '
        'of a value, not the value itself), works through common mistakes '
        'like forgetting to await inside a loop, then moves on to Streams '
        'for values that arrive over time.\n\n'
        'We close with a plain-language explanation of isolates - Dart\'s '
        'answer to true parallelism, since there is no shared-memory '
        'threading - and a small example moving expensive JSON parsing off '
        'the UI thread so the app never janks. You will leave able to '
        'explain, not just use, every one of these tools.',
  ),
  SmartAcademyEntry(
    id: 'v6',
    kind: SmartAcademyEntryKind.video,
    title:
        'Responsive UI: Designing for Phone, Tablet, and Web from One Codebase',
    authorName: 'Diego Fuentes',
    durationLabel: '16:28',
    description:
        'Flutter\'s promise is one codebase everywhere, but a layout that '
        'looks great on a phone often looks cramped or absurdly stretched '
        'on a tablet or browser window. This video covers the practical '
        'toolkit for handling that: LayoutBuilder for width-based '
        'decisions, MediaQuery for device-level info, and when to reach for '
        'a completely different layout versus just adjusting spacing.\n\n'
        'We build one screen that reflows from a single column on a phone '
        'to a multi-column grid on a wide window, live, resizing the '
        'preview the whole time so you can see exactly which breakpoint '
        'triggers which layout change. The techniques are the same ones '
        'used to build the SmartAcademy hub page you are on right now.',
  ),
];

const List<SmartAcademyEntry> sampleForumEntries = [
  SmartAcademyEntry(
    id: 'f1',
    kind: SmartAcademyEntryKind.forum,
    title: 'Why does my ListView.builder rebuild every item on scroll?',
    authorName: 'jordan_codes',
    description:
        'I\'ve got a ListView.builder with about 200 items, each a fairly '
        'heavy card widget with a network image and computed formatting. '
        'Scrolling is noticeably janky, and when I added a print in '
        'itemBuilder I can see items rebuilding far more often than '
        'expected - including ones already fully off-screen.\n\n'
        'I\'ve wrapped the expensive formatting in a late final inside the '
        'item widget itself rather than recomputing it in itemBuilder, and '
        'that helped a little, but the jank is still there. Is this normal '
        'ListView.builder recycling behavior I\'m misreading, or is there '
        'something about AutomaticKeepAliveClientMixin or const '
        'constructors I\'m missing?',
  ),
  SmartAcademyEntry(
    id: 'f2',
    kind: SmartAcademyEntryKind.forum,
    title: 'Best practices for folder structure in a mid-size Flutter app?',
    authorName: 'sara_dev',
    description:
        'My app started as a single lib/ folder with everything dumped in '
        'together, and it has grown past the point where that\'s '
        'manageable - I\'m now at around 40 screens and it\'s getting hard '
        'to find anything. I\'ve seen "feature-first" (folder per feature, '
        'with its own widgets/logic/models inside) and "layer-first" '
        '(top-level widgets/, models/, services/ folders shared across '
        'features) both recommended, and I can\'t tell which actually '
        'scales better in practice versus just looking cleaner in a blog '
        'post.\n\n'
        'For people who have actually migrated a real app between these '
        'two styles: what broke, what got easier, and would you do it '
        'again? I\'m especially curious how either approach handles code '
        'that\'s genuinely shared between three or four features without '
        'turning into a dumping-ground "shared" folder that becomes its own '
        'mess.',
  ),
  SmartAcademyEntry(
    id: 'f3',
    kind: SmartAcademyEntryKind.forum,
    title: 'How do you handle form validation without a package?',
    authorName: 'mkoenig',
    description:
        'I\'d rather not pull in a form-validation package for a login and '
        'signup form with maybe six fields total - it feels like a lot of '
        'dependency for something Form and TextFormField\'s validator '
        'already mostly cover. Right now I\'m writing a plain function per '
        'field (isValidEmail, isValidPassword, etc.) and wiring them up '
        'individually, which works but feels like it\'ll get repetitive if '
        'the app grows.\n\n'
        'Is there a clean middle ground between "write everything by hand" '
        'and "pull in a whole package" - like a small shared validators '
        'file plus a consistent pattern for showing the error text, that '
        'people have settled on? Mostly want to avoid re-inventing this '
        'badly and having every form in the app look slightly different.',
  ),
  SmartAcademyEntry(
    id: 'f4',
    kind: SmartAcademyEntryKind.forum,
    title: 'Isolates vs compute() — when is the extra complexity worth it?',
    authorName: 'lina_wu',
    description:
        'I\'m parsing a fairly large JSON response (a few thousand rows) on '
        'app startup and noticed a small but real frame drop while it '
        'happens. compute() seems like the obvious fix since it\'s a single '
        'function call, but I\'ve also seen people reach straight for a '
        'manually managed Isolate with its own SendPort/ReceivePort for '
        'similar-sounding problems, and I don\'t have a good feel for where '
        'the line is.\n\n'
        'Is compute() basically "good enough" for anything that\'s a single '
        'in-and-out computation, and manual isolates only really pay off '
        'when you need an isolate that stays alive and handles multiple '
        'messages over time (like a background sync worker)? Would love to '
        'hear from anyone who started with compute() and later had to '
        'switch, and what specifically forced the switch.',
  ),
];
