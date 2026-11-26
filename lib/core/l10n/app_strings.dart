enum AppLanguage { ko, ja }

class AppStrings {
  final AppLanguage lang;

  const AppStrings(this.lang);

  bool get isKo => lang == AppLanguage.ko;

  String get appTitle => isKo ? '네리마 분리배출' : '練馬ごみナビ';

  // Navigation tabs
  String get navHome => isKo ? '홈' : 'ホーム';
  String get navCalendar => isKo ? '캘린더' : 'カレンダー';
  String get navDictionary => isKo ? '분리배출 사전' : '分別辞典';
  String get navSettings => isKo ? '안내 · 설정' : '案内・設定';

  // Home screen
  String get today => isKo ? '오늘' : '今日';
  String get tomorrow => isKo ? '내일' : '明日';
  String get nextCollection => isKo ? '다음 수거일' : '次の収集日';
  String get noCollectionToday =>
      isKo ? '오늘은 수거가 없는 날이에요' : '今日は収集がありません';
  String get noCollectionTomorrow =>
      isKo ? '내일은 수거가 없는 날이에요' : '明日は収集がありません';
  String get holidayNotice =>
      isKo ? '연말연시 수거 휴무일입니다' : '年末年始の収集休止日です';
  String get thisWeek => isKo ? '이번 주 수거 일정' : '今週のスケジュール';
  String get upcomingNonBurnable =>
      isKo ? '다음 불연쓰레기' : '次の不燃ごみ';
  String get nerimaruGallery => isKo ? '네리마루 갤러리' : 'ねり丸ギャラリー';
  String get nerimaruPlaceholderTitle =>
      isKo ? '네리마루(ねり丸) 사진 슬라이드' : 'ねり丸フォトスライド';
  String get nerimaruPlaceholderSub => isKo
      ? 'assets/images/nerimaru/ 폴더에 이미지를 넣으면 자동으로 슬라이드됩니다'
      : 'assets/images/nerimaru/ に画像を入れると自動でスライド表示されます';
  String deadlineLabel(String time) => isKo ? '$time까지' : '$timeまで';
  String dDayLabel(int days) {
    if (days == 0) return 'D-Day';
    return 'D-$days';
  }

  // Calendar & Alarms
  String get calendarTitle => isKo ? '수거 캘린더' : '収集カレンダー';
  String get alarmSettingsTitle => isKo ? '로컬 알람 규칙' : 'アラーム設定';
  String get addAlarm => isKo ? '알람 추가' : 'アラーム追加';
  String get editAlarm => isKo ? '알람 수정' : 'アラーム編集';
  String get delete => isKo ? '삭제' : '削除';
  String get save => isKo ? '저장' : '保存';
  String get cancel => isKo ? '취소' : 'キャンセル';
  String get noAlarmsYet => isKo
      ? '등록된 알람이 없습니다.\n+ 버튼으로 원하는 시간의 알람을 추가해보세요.'
      : 'アラームが未登録です。\n＋ボタンから希望の時間で追加してください。';
  String get allCategories => isKo ? '모든 품목' : 'すべての種別';
  String get selectCategories => isKo ? '알림 받을 품목' : '通知する種別';
  String get alarmTiming => isKo ? '알림 시점' : '通知タイミング';
  String get alarmTime => isKo ? '알림 시간' : '通知時刻';
  String get testNotification => isKo ? '테스트 알림' : 'テスト通知';
  String get testNotificationSent =>
      isKo ? '테스트 알림을 보냈습니다.' : 'テスト通知を送信しました。';
  String daysBeforeLabel(int daysBefore) {
    if (daysBefore == 0) return isKo ? '배출 당일' : '収集当日';
    return isKo ? '배출 $daysBefore일 전' : '収集$daysBefore日前';
  }

  String get localOnlyHint => isKo
      ? '구글/삼성 캘린더 연동 없이 앱 자체 알람으로 동작합니다.'
      : '外部カレンダーと連携せず、アプリ独自のローカル通知で動作します。';

  // Dictionary
  String get dictionaryTitle => isKo ? '분리배출 사전' : 'ごみ分別辞典';
  String get searchHint => isKo
      ? '한국어 또는 일본어 입력 (예: 후라이팬, 傘, ペット)'
      : '日本語・韓国語で検索 (例: フライパン, 우산, 傘)';
  String get filterAll => isKo ? '전체' : 'すべて';
  String get noSearchResults => isKo
      ? '검색 결과가 없습니다.\n다른 단어나 일본어/한국어로 검색해보세요.'
      : '該当する品目が見つかりません。\n別の言葉で検索してみてください。';
  String get disposalTip => isKo ? '배출 방법 · 주의사항' : '出し方・注意点';
  String get nextScheduledForItem =>
      isKo ? '내 지역 다음 배출일' : 'マイ地域の次回収集日';

  // Settings & Official Links
  String get settingsTitle => isKo ? '안내 · 설정' : '案内・設定';
  String get myAreaSection => isKo ? '내 지역 · 수거 요일' : 'マイ地域・収集曜日';
  String get selectAreaPreset => isKo ? '지역 프리셋 선택' : '地域プリセット選択';
  String get editScheduleManually =>
      isKo ? '요일 / 주차 직접 수정' : '曜日・第○週を手動編集';
  String get customScheduleBadge => isKo ? '직접 수정됨' : 'カスタム設定';
  String get officialWebSection =>
      isKo ? '공식 웹 페이지 바로가기' : '公式Webページ（ブラウザ）';
  String get officialPhoneSection =>
      isKo ? '관련 부서 전화번호' : 'お問い合わせ・電話番号';
  String get appPreferencesSection => isKo ? '앱 환경 설정' : 'アプリ設定';
  String get languageLabel => isKo ? '표시 언어' : '表示言語';
  String get themeLabel => isKo ? '테마' : 'テーマ';
  String get themeSystem => isKo ? '시스템' : 'システム';
  String get themeLight => isKo ? '라이트' : 'ライト';
  String get themeDark => isKo ? '다크' : 'ダーク';

  // Schedule editor
  String get ruleTypeNone => isKo ? '설정 안 함' : '設定なし';
  String get ruleTypeWeekly => isKo ? '매주' : '毎週';
  String get ruleTypeNthWeekday => isKo ? '매월 지정 주차' : '毎月 第○週';
  String get selectWeekdays => isKo ? '요일 선택' : '曜日を選択';
  String get selectWeeks => isKo ? '주차 선택' : '第何週を選択';
  String nthWeekLabel(int week) => isKo ? '제$week주' : '第$week週';

  List<String> get weekdayShort => isKo
      ? const ['월', '화', '수', '목', '금', '토', '일']
      : const ['月', '火', '水', '木', '金', '土', '日'];

  String weekdayName(int weekday) => weekdayShort[(weekday - 1).clamp(0, 6)];

  String formatMonthDay(DateTime date) {
    final wd = weekdayName(date.weekday);
    return isKo
        ? '${date.month}월 ${date.day}일 ($wd)'
        : '${date.month}月${date.day}日 ($wd)';
  }

  String formatYearMonth(DateTime date) {
    return isKo ? '${date.year}년 ${date.month}월' : '${date.year}年${date.month}月';
  }
}
