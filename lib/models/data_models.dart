class WatchingRender {
  final SkinnyRender item;
  final int current;
  final int total;
  final int episodeId;
  final int fileId;

  WatchingRender({
    required this.item,
    required this.current,
    required this.total,
    required this.episodeId,
    required this.fileId,
  });

  factory WatchingRender.fromJson(Map<String, dynamic> json) => WatchingRender(
    item: SkinnyRender.fromJson(json['ITEM']),
    current: json['CURRENT'],
    total: json['TOTAL'],
    episodeId: json['EPISODE_ID'],
    fileId: json['FILE_ID'],
  );

  Map<String, dynamic> toJson() => {
    'ITEM': item.toJson(),
    'CURRENT': current,
    'TOTAL': total,
    'EPISODE_ID': episodeId,
    'FILE_ID': fileId,
  };
}

class LineRender {
  final List<SkinnyRender> data;
  final String title;
  final String type;

  LineRender({required this.data, required this.title, required this.type});

  factory LineRender.fromJson(Map<String, dynamic> json) => LineRender(
    data: (json['Data'] as List).map((e) => SkinnyRender.fromJson(e)).toList(),
    title: json['Title'],
    type: json['Type'],
  );

  Map<String, dynamic> toJson() => {
    'Data': data.map((e) => e.toJson()).toList(),
    'Title': title,
    'Type': type,
  };
}

class Provider {
  final int providerId;
  final String url;
  final String providerName;
  final int displayPriority;

  Provider({
    required this.providerId,
    required this.url,
    required this.providerName,
    required this.displayPriority,
  });

  factory Provider.fromJson(Map<String, dynamic> json) => Provider(
    providerId: json['PROVIDER_ID'],
    url: json['URL'],
    providerName: json['PROVIDER_NAME'],
    displayPriority: json['DISPLAY_PRIORITY'],
  );

  Map<String, dynamic> toJson() => {
    'PROVIDER_ID': providerId,
    'URL': url,
    'PROVIDER_NAME': providerName,
    'DISPLAY_PRIORITY': displayPriority,
  };
}

class LineRenderProvider {
  final List<Provider> data;
  final String title;
  final String type;

  LineRenderProvider({
    required this.data,
    required this.title,
    required this.type,
  });

  factory LineRenderProvider.fromJson(Map<String, dynamic> json) =>
      LineRenderProvider(
        data: (json['Data'] as List).map((e) => Provider.fromJson(e)).toList(),
        title: json['Title'],
        type: json['Type'],
      );

  Map<String, dynamic> toJson() => {
    'Data': data.map((e) => e.toJson()).toList(),
    'Title': title,
    'Type': type,
  };
}

class Dimension {
  final double width;
  final double height;

  Dimension({required this.width, required this.height});

  factory Dimension.fromJson(Map<String, dynamic> json) => Dimension(
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {'width': width, 'height': height};
}

class ApiHome {
  final LineRender recents;
  final List<LineRender> lines;
  final List<LineRenderProvider> providers;

  ApiHome({
    required this.recents,
    required this.lines,
    required this.providers,
  });

  factory ApiHome.fromJson(Map<String, dynamic> json) => ApiHome(
    recents: LineRender.fromJson(json['Recents']),
    lines: (json['Lines'] as List).map((e) => LineRender.fromJson(e)).toList(),
    providers:
        (json['Providers'] as List)
            .map((e) => LineRenderProvider.fromJson(e))
            .toList(),
  );

  Map<String, dynamic> toJson() => {
    'Recents': recents.toJson(),
    'Lines': lines.map((e) => e.toJson()).toList(),
    'Providers': providers.map((e) => e.toJson()).toList(),
  };
}

class Genre {
  final int id;
  final String name;

  Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(id: json['ID'], name: json['NAME']);

  Map<String, dynamic> toJson() => {'ID': id, 'NAME': name};
}

class ProviderItem {
  final int providerId;
  final String url;
  final String providerName;
  final int displayPriority;

  ProviderItem({
    required this.providerId,
    required this.url,
    required this.providerName,
    required this.displayPriority,
  });

  factory ProviderItem.fromJson(Map<String, dynamic> json) => ProviderItem(
    providerId: json['PROVIDER_ID'],
    url: json['URL'],
    providerName: json['PROVIDER_NAME'],
    displayPriority: json['DISPLAY_PRIORITY'],
  );

  Map<String, dynamic> toJson() => {
    'PROVIDER_ID': providerId,
    'URL': url,
    'PROVIDER_NAME': providerName,
    'DISPLAY_PRIORITY': displayPriority,
  };
}

class SkinnyRender {
  final String id;
  final String type;
  final String name;
  final String poster;
  final String backdrop;
  final String description;
  final dynamic year;
  final String runtime;
  final List<Genre> genre;
  final String trailer;
  final WatchData watch;
  bool watchlisted;
  final String logo;
  final String transcodeUrl;
  final List<ProviderItem> providers;
  final String displayData;
  final String? logoUrl; // If LOGO is a URL, else remove
  final String? transcodedUrl; // If TRANSCODE_URL is a URL, else remove

  SkinnyRender({
    required this.id,
    required this.type,
    required this.name,
    required this.poster,
    required this.backdrop,
    required this.description,
    required this.year,
    required this.runtime,
    required this.genre,
    required this.trailer,
    required this.watch,
    required this.watchlisted,
    required this.logo,
    required this.transcodeUrl,
    required this.providers,
    required this.displayData,
    this.logoUrl,
    this.transcodedUrl,
  });

  factory SkinnyRender.fromJson(Map<String, dynamic> json) => SkinnyRender(
    id: json['ID'],
    type: json['TYPE'],
    name: json['NAME'],
    poster: json['POSTER'],
    backdrop: json['BACKDROP'],
    description: json['DESCRIPTION'],
    year: json['YEAR'],
    runtime: json['RUNTIME'],
    genre: (json['GENRE'] as List).map((e) => Genre.fromJson(e)).toList(),
    trailer: json['TRAILER'],
    watch: WatchData.fromJson(json['WATCH']),
    watchlisted: json['WATCHLISTED'],
    logo: json['LOGO'],
    transcodeUrl: json['TRANSCODE_URL'],
    providers:
        (json['PROVIDERS'] as List)
            .map((e) => ProviderItem.fromJson(e))
            .toList(),
    displayData: json['DisplayData'],
    logoUrl: json['LOGO'],
    transcodedUrl: json['TRANSCODE_URL'],
  );

  Map<String, dynamic> toJson() => {
    'ID': id,
    'TYPE': type,
    'NAME': name,
    'POSTER': poster,
    'BACKDROP': backdrop,
    'DESCRIPTION': description,
    'YEAR': year,
    'RUNTIME': runtime,
    'GENRE': genre.map((e) => e.toJson()).toList(),
    'TRAILER': trailer,
    'WATCH': watch.toJson(),
    'WATCHLISTED': watchlisted,
    'LOGO': logo,
    'TRANSCODE_URL': transcodeUrl,
    'PROVIDERS': providers.map((e) => e.toJson()).toList(),
    'DisplayData': displayData,
  };
}

class WatchData {
  final int current;
  final int total;

  WatchData({required this.current, required this.total});

  factory WatchData.fromJson(Map<String, dynamic> json) =>
      WatchData(current: json['CURRENT'], total: json['TOTAL']);

  Map<String, dynamic> toJson() => {'CURRENT': current, 'TOTAL': total};
}

class FileItem {
  final int id;
  final String filename;
  final String downloadUrl;
  final String transcodeUrl;
  final int current;
  final int size;

  FileItem({
    required this.id,
    required this.filename,
    required this.downloadUrl,
    required this.transcodeUrl,
    required this.current,
    required this.size,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) => FileItem(
    id: json['ID'],
    filename: json['FILENAME'],
    downloadUrl: json['DOWNLOAD_URL'],
    transcodeUrl: json['TRANSCODE_URL'],
    current: json['CURRENT'],
    size: json['SIZE'],
  );

  Map<String, dynamic> toJson() => {
    'ID': id,
    'FILENAME': filename,
    'DOWNLOAD_URL': downloadUrl,
    'TRANSCODE_URL': transcodeUrl,
    'CURRENT': current,
    'SIZE': size,
  };
}

class MovieItem {
  final String id;
  final String displayName;
  final String logo;
  final dynamic year;
  final List<FileItem> files;
  final WatchData watch;
  final String budget;
  final String awards;
  final String director;
  final String writer;
  final String tagline;
  final double voteAverage;
  final List<Provider> providers;
  final String type;
  final String description;
  final String runtime;
  final List<SkinnyRender> similars;
  bool watchlisted;
  final List<Genre> genre;
  final String backdrop;
  final String poster;
  final String downloadUrl;
  final String transcodeUrl;
  final String trailer;

  MovieItem({
    required this.id,
    required this.displayName,
    required this.logo,
    required this.year,
    required this.files,
    required this.watch,
    required this.budget,
    required this.awards,
    required this.director,
    required this.writer,
    required this.tagline,
    required this.voteAverage,
    required this.providers,
    required this.type,
    required this.description,
    required this.runtime,
    required this.similars,
    required this.watchlisted,
    required this.genre,
    required this.backdrop,
    required this.poster,
    required this.downloadUrl,
    required this.transcodeUrl,
    required this.trailer,
  });

  factory MovieItem.fromJson(Map<String, dynamic> json) => MovieItem(
    id: json['ID'],
    displayName: json['DISPLAY_NAME'],
    logo: json['LOGO'],
    year: json['YEAR'],
    files: (json['FILES'] as List).map((e) => FileItem.fromJson(e)).toList(),
    watch: WatchData.fromJson(json['WATCH']),
    budget: json['BUDGET'],
    awards: json['AWARDS'],
    director: json['DIRECTOR'] ?? "",
    writer: json['WRITER'] ?? "",
    tagline: json['TAGLINE'] ?? "",
    voteAverage: (json['Vote_average'] as num?)?.toDouble() ?? 0.0,
    providers:
        (json['PROVIDERS'] as List).map((e) => Provider.fromJson(e)).toList(),
    type: json['TYPE'],
    description: json['DESCRIPTION'],
    runtime: json['RUNTIME'],
    similars:
        (json['SIMILARS'] as List)
            .map((e) => SkinnyRender.fromJson(e))
            .toList(),
    watchlisted: json['WATCHLISTED'],
    genre: (json['GENRE'] as List).map((e) => Genre.fromJson(e)).toList(),
    backdrop: json['BACKDROP'],
    poster: json['POSTER'],
    downloadUrl: json['DOWNLOAD_URL'],
    transcodeUrl: json['TRANSCODE_URL'],
    trailer: json['TRAILER'] ?? "",
  );

  Map<String, dynamic> toJson() => {
    'ID': id,
    'DISPLAY_NAME': displayName,
    'LOGO': logo,
    'YEAR': year,
    'FILES': files.map((e) => e.toJson()).toList(),
    'WATCH': watch.toJson(),
    'BUDGET': budget,
    'AWARDS': awards,
    'DIRECTOR': director,
    'WRITER': writer,
    'TAGLINE': tagline,
    'Vote_average': voteAverage,
    'PROVIDERS': providers.map((e) => e.toJson()).toList(),
    'TYPE': type,
    'DESCRIPTION': description,
    'RUNTIME': runtime,
    'SIMILARS': similars.map((e) => e.toJson()).toList(),
    'WATCHLISTED': watchlisted,
    'GENRE': genre.map((e) => e.toJson()).toList(),
    'BACKDROP': backdrop,
    'POSTER': poster,
    'DOWNLOAD_URL': downloadUrl,
    'TRANSCODE_URL': transcodeUrl,
    'TRAILER': trailer,
  };
}

// TV data models for the application

class TVItem {
  final String ID;
  final int TMDB_ID;
  final String TYPE; // Always "tv"
  final String DISPLAY_NAME;
  final String LOGO;
  final dynamic YEAR;
  final List<SkinnyRender> SIMILARS;
  bool WATCHLISTED;
  final String AWARDS;
  final String DIRECTOR;
  final NextFile NEXT;
  final String WRITER;
  final double Vote_average;
  final String TAGLINE;
  final List<Provider> PROVIDERS;
  final String DESCRIPTION;
  final int RUNTIME;
  final List<Genre> GENRE;
  final String BACKDROP;
  final String POSTER;
  final List<SEASON> SEASONS;
  final List<FileItem> FILES;
  final String TRAILER;

  TVItem({
    required this.ID,
    this.TMDB_ID = 0,
    required this.TYPE,
    required this.DISPLAY_NAME,
    required this.LOGO,
    required this.YEAR,
    required this.SIMILARS,
    required this.WATCHLISTED,
    required this.AWARDS,
    required this.DIRECTOR,
    required this.NEXT,
    required this.WRITER,
    required this.Vote_average,
    required this.TAGLINE,
    required this.PROVIDERS,
    required this.DESCRIPTION,
    required this.RUNTIME,
    required this.GENRE,
    required this.BACKDROP,
    required this.POSTER,
    required this.SEASONS,
    required this.FILES,
    required this.TRAILER,
  });

  factory TVItem.fromJson(Map<String, dynamic> json) {
    return TVItem(
      ID: json['ID'] ?? '',
      TMDB_ID: json['TMDB_ID'] ?? 0,
      TYPE: json['TYPE'] ?? 'tv',
      DISPLAY_NAME: json['DISPLAY_NAME'] ?? '',
      LOGO: json['LOGO'] ?? '',
      YEAR: json['YEAR'],
      SIMILARS:
          (json['SIMILARS'] as List? ?? [])
              .map((e) => SkinnyRender.fromJson(e))
              .toList(),
      WATCHLISTED: json['WATCHLISTED'] ?? false,
      AWARDS: json['AWARDS'] ?? '',
      DIRECTOR: json['DIRECTOR'] ?? '',
      NEXT: NextFile.fromJson(json['NEXT'] ?? {}),
      WRITER: json['WRITER'] ?? '',
      Vote_average: (json['Vote_average'] as num?)?.toDouble() ?? 0.0,
      TAGLINE: json['TAGLINE'] ?? '',
      PROVIDERS:
          (json['PROVIDERS'] as List? ?? [])
              .map((e) => Provider.fromJson(e))
              .toList(),
      DESCRIPTION: json['DESCRIPTION'] ?? '',
      RUNTIME: json['RUNTIME'] ?? 0,
      GENRE:
          (json['GENRE'] as List? ?? []).map((e) => Genre.fromJson(e)).toList(),
      BACKDROP: json['BACKDROP'] ?? '',
      POSTER: json['POSTER'] ?? '',
      SEASONS:
          (json['SEASONS'] as List? ?? [])
              .map((e) => SEASON.fromJson(e))
              .toList(),
      FILES:
          (json['FILES'] as List? ?? [])
              .map((e) => FileItem.fromJson(e))
              .toList(),
      TRAILER: json['TRAILER'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'ID': ID,
    'TMDB_ID': TMDB_ID,
    'TYPE': TYPE,
    'DISPLAY_NAME': DISPLAY_NAME,
    'LOGO': LOGO,
    'YEAR': YEAR,
    'SIMILARS': SIMILARS.map((e) => e.toJson()).toList(),
    'WATCHLISTED': WATCHLISTED,
    'AWARDS': AWARDS,
    'DIRECTOR': DIRECTOR,
    'NEXT': NEXT.toJson(),
    'WRITER': WRITER,
    'Vote_average': Vote_average,
    'TAGLINE': TAGLINE,
    'PROVIDERS': PROVIDERS.map((e) => e.toJson()).toList(),
    'DESCRIPTION': DESCRIPTION,
    'RUNTIME': RUNTIME,
    'GENRE': GENRE.map((e) => e.toJson()).toList(),
    'BACKDROP': BACKDROP,
    'POSTER': POSTER,
    'SEASONS': SEASONS.map((e) => e.toJson()).toList(),
    'FILES': FILES.map((e) => e.toJson()).toList(),
    'TRAILER': TRAILER,
  };
}

class SEASON {
  final int ID;
  final int SEASON_NUMBER;
  final String NAME;
  final String DESCRIPTION;
  final String BACKDROP;
  final List<EPISODE> EPISODES;

  SEASON({
    required this.ID,
    required this.SEASON_NUMBER,
    required this.NAME,
    required this.DESCRIPTION,
    required this.BACKDROP,
    required this.EPISODES,
  });

  factory SEASON.fromJson(Map<String, dynamic> json) {
    return SEASON(
      ID: json['ID'] ?? 0,
      SEASON_NUMBER: json['SEASON_NUMBER'] ?? 0,
      NAME: json['NAME'] ?? '',
      DESCRIPTION: json['DESCRIPTION'] ?? '',
      BACKDROP: json['BACKDROP'] ?? '',
      EPISODES:
          (json['EPISODES'] as List? ?? [])
              .map((e) => EPISODE.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'ID': ID,
    'SEASON_NUMBER': SEASON_NUMBER,
    'NAME': NAME,
    'DESCRIPTION': DESCRIPTION,
    'BACKDROP': BACKDROP,
    'EPISODES': EPISODES.map((e) => e.toJson()).toList(),
  };
}

class EPISODE {
  final int ID;
  final String TYPE; // Always "episode"
  final int EPISODE_NUMBER;
  final List<FileItem> FILES;
  final String NAME;
  final String DESCRIPTION;
  final String STILL;
  final String TRANSCODE_URL;
  final WatchData WATCH;
  final String DOWNLOAD_URL;

  EPISODE({
    required this.ID,
    required this.TYPE,
    required this.EPISODE_NUMBER,
    required this.FILES,
    required this.NAME,
    required this.DESCRIPTION,
    required this.STILL,
    required this.TRANSCODE_URL,
    required this.WATCH,
    required this.DOWNLOAD_URL,
  });

  factory EPISODE.fromJson(Map<String, dynamic> json) {
    return EPISODE(
      ID: json['ID'] ?? 0,
      TYPE: json['TYPE'] ?? 'episode',
      EPISODE_NUMBER: json['EPISODE_NUMBER'] ?? 0,
      FILES:
          (json['FILES'] as List? ?? [])
              .map((e) => FileItem.fromJson(e))
              .toList(),
      NAME: json['NAME'] ?? '',
      DESCRIPTION: json['DESCRIPTION'] ?? '',
      STILL: json['STILL'] ?? '',
      TRANSCODE_URL: json['TRANSCODE_URL'] ?? '',
      WATCH: WatchData.fromJson(json['WATCH'] ?? {}),
      DOWNLOAD_URL: json['DOWNLOAD_URL'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'ID': ID,
    'TYPE': TYPE,
    'EPISODE_NUMBER': EPISODE_NUMBER,
    'FILES': FILES.map((e) => e.toJson()).toList(),
    'NAME': NAME,
    'DESCRIPTION': DESCRIPTION,
    'STILL': STILL,
    'TRANSCODE_URL': TRANSCODE_URL,
    'WATCH': WATCH.toJson(),
    'DOWNLOAD_URL': DOWNLOAD_URL,
  };
}

class NextFile {
  final String TYPE;
  final String TRANSCODE_URL;
  final String DOWNLOAD_URL;
  final String BACKDROP;
  final String NAME;
  final String FILENAME;
  final String INFO;

  NextFile({
    required this.TYPE,
    required this.TRANSCODE_URL,
    required this.DOWNLOAD_URL,
    required this.BACKDROP,
    required this.NAME,
    required this.FILENAME,
    required this.INFO,
  });

  factory NextFile.fromJson(Map<String, dynamic> json) {
    return NextFile(
      TYPE: json['TYPE'] ?? 'unknown',
      TRANSCODE_URL: json['TRANSCODE_URL'] ?? '',
      DOWNLOAD_URL: json['DOWNLOAD_URL'] ?? '',
      BACKDROP: json['BACKDROP'] ?? '',
      NAME: json['NAME'] ?? '',
      FILENAME: json['FILENAME'] ?? '',
      INFO: json['INFO'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'TYPE': TYPE,
    'TRANSCODE_URL': TRANSCODE_URL,
    'DOWNLOAD_URL': DOWNLOAD_URL,
    'BACKDROP': BACKDROP,
    'NAME': NAME,
    'FILENAME': FILENAME,
    'INFO': INFO,
  };
}

class AvailableTorrent {
  String? id;
  String? providerName;
  String? name;
  String? link;
  int? seed;
  int? size;
  List<String>? flags;

  AvailableTorrent({
    this.id,
    this.providerName,
    this.name,
    this.link,
    this.seed,
    this.size,
    this.flags,
  });

  factory AvailableTorrent.fromJson(Map<String, dynamic> json) {
    return AvailableTorrent(
      id: json['id']?.toString(),
      providerName: json['provider_name']?.toString(),
      name: json['name']?.toString(),
      link: json['link']?.toString(),
      seed: json['seed'] != null ? int.tryParse(json['seed'].toString()) : null,
      size: json['size'] != null ? int.tryParse(json['size'].toString()) : null,
      flags:
          json['Flags'] != null
              ? (json['Flags'] as List).map((e) => e.toString()).toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['provider_name'] = this.providerName;
    data['name'] = this.name;
    data['link'] = this.link;
    data['seed'] = this.seed;
    data['size'] = this.size;
    data['Flags'] = this.flags;
    return data;
  }
}

class QUALITY {
  final String name;
  final int height;
  final int width;

  QUALITY({required this.name, required this.height, required this.width});

  factory QUALITY.fromJson(Map<String, dynamic> json) => QUALITY(
    name: json['name'] ?? '',
    height: json['height'] ?? 0,
    width: json['width'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'height': height,
    'width': width,
  };
}

class AUDIO_TRACK {
  final String language;
  final String name;
  final String id;

  AUDIO_TRACK({required this.language, required this.name, required this.id});

  factory AUDIO_TRACK.fromJson(Map<String, dynamic> json) => AUDIO_TRACK(
    language: json['language'] ?? '',
    name: json['name'] ?? '',
    id: json['id'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'language': language,
    'name': name,
    'id': id,
  };
}

class SUBTITLE {
  final String language;
  final String name;
  final String id;

  SUBTITLE({required this.language, required this.name, required this.id});

  factory SUBTITLE.fromJson(Map<String, dynamic> json) => SUBTITLE(
    language: json['language'] ?? '',
    name: json['name'] ?? '',
    id: json['id'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'language': language,
    'name': name,
    'id': id,
  };
}

class SeasonItem {
  final int id;
  final String name;
  final int seasonNumber;

  SeasonItem({
    required this.id,
    required this.name,
    required this.seasonNumber,
  });

  factory SeasonItem.fromJson(Map<String, dynamic> json) => SeasonItem(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    seasonNumber: json['season_number'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'season_number': seasonNumber,
  };
}

class TranscoderRes {
  final String manifest;
  final String downloadUrl;
  final String uuid;
  final List<QUALITY> qualitys;
  final List<AUDIO_TRACK> tracks;
  final List<SUBTITLE> subtitles;
  final int current;
  final int total;
  final List<SeasonItem> seasons;
  final String name;
  final String poster;
  final String backdrop;
  final bool isLive;
  final NextFile next;
  final int taskId;
  final bool isBrowserPlayable;

  TranscoderRes({
    required this.manifest,
    required this.downloadUrl,
    required this.uuid,
    required this.qualitys,
    required this.tracks,
    required this.subtitles,
    required this.current,
    required this.total,
    required this.seasons,
    required this.name,
    required this.poster,
    required this.backdrop,
    required this.isLive,
    required this.next,
    required this.taskId,
    required this.isBrowserPlayable,
  });

  factory TranscoderRes.fromJson(Map<String, dynamic> json) => TranscoderRes(
    manifest: json['manifest'] ?? '',
    downloadUrl: json['download_url'] ?? '',
    uuid: json['uuid'] ?? '',
    qualitys:
        (json['qualitys'] as List? ?? [])
            .map((e) => QUALITY.fromJson(e))
            .toList(),
    tracks:
        (json['tracks'] as List? ?? [])
            .map((e) => AUDIO_TRACK.fromJson(e))
            .toList(),
    subtitles:
        (json['subtitles'] as List? ?? [])
            .map((e) => SUBTITLE.fromJson(e))
            .toList(),
    current: json['current'] ?? 0,
    total: json['total'] ?? 0,
    seasons:
        (json['seasons'] as List? ?? [])
            .map((e) => SeasonItem.fromJson(e))
            .toList(),
    name: json['name'] ?? '',
    poster: json['poster'] ?? '',
    backdrop: json['backdrop'] ?? '',
    isLive: json['isLive'] ?? false,
    next: NextFile.fromJson(json['next'] ?? {}),
    taskId: json['task_id'] ?? 0,
    isBrowserPlayable: json['isBrowserPlayable'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'manifest': manifest,
    'download_url': downloadUrl,
    'uuid': uuid,
    'qualitys': qualitys.map((e) => e.toJson()).toList(),
    'tracks': tracks.map((e) => e.toJson()).toList(),
    'subtitles': subtitles.map((e) => e.toJson()).toList(),
    'current': current,
    'total': total,
    'seasons': seasons.map((e) => e.toJson()).toList(),
    'name': name,
    'poster': poster,
    'backdrop': backdrop,
    'isLive': isLive,
    'next': next.toJson(),
    'task_id': taskId,
    'isBrowserPlayable': isBrowserPlayable,
  };
}
