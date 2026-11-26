class OfficialLinkItem {
  final String id;
  final String titleKo;
  final String titleJa;
  final String subtitleKo;
  final String subtitleJa;
  final String url;

  const OfficialLinkItem({
    required this.id,
    required this.titleKo,
    required this.titleJa,
    required this.subtitleKo,
    required this.subtitleJa,
    required this.url,
  });
}

class OfficialPhoneItem {
  final String id;
  final String titleKo;
  final String titleJa;
  final String subtitleKo;
  final String subtitleJa;
  final String phone;

  const OfficialPhoneItem({
    required this.id,
    required this.titleKo,
    required this.titleJa,
    required this.subtitleKo,
    required this.subtitleJa,
    required this.phone,
  });
}

class NerimaOfficialResources {
  static const List<OfficialLinkItem> webLinks = [
    OfficialLinkItem(
      id: 'monthly_schedule',
      titleKo: '월간 수거일 · 지역별 수집요일 일람',
      titleJa: '地域別収集曜日一覧・年間カレンダー',
      subtitleKo: '네리마구 공식 홈페이지에서 동네별 최신 수거일 확인',
      subtitleJa: '練馬区公式HPで町丁目別の最新収集日を確認',
      url: 'https://www.city.nerima.tokyo.jp/kurashi/gomi/wakekata/ichiran/index.html',
    ),
    OfficialLinkItem(
      id: 'sodai_reservation',
      titleKo: '대형쓰레기(粗大ごみ) 인터넷 예약',
      titleJa: '粗大ごみインターネット受付',
      subtitleKo: '24시간 온라인 신청 · 수수료 확인',
      subtitleJa: '24時間オンライン申込・手数料確認',
      url: 'https://www.sodai-nerima.jp',
    ),
    OfficialLinkItem(
      id: 'sorting_guide',
      titleKo: '네리마구 자원·쓰레기 분리배출 안내',
      titleJa: '資源・ごみの分け方・出し方ガイド',
      subtitleKo: '종류별 배출 규칙 및 주의사항 공식 페이지',
      subtitleJa: '種別ごとのルール・注意点の公式案内',
      url: 'https://www.city.nerima.tokyo.jp/kurashi/gomi/wakekata/index.html',
    ),
  ];

  static const List<OfficialPhoneItem> phoneContacts = [
    OfficialPhoneItem(
      id: 'sodai_center',
      titleKo: '네리마구 대형쓰레기 접수센터',
      titleJa: '練馬区粗大ごみ受付センター',
      subtitleKo: '월~토 08:00~19:00 (일요일·연말연시 휴무)',
      subtitleJa: '月〜土 8:00〜19:00（日曜・年末年始除く）',
      phone: '03-5703-5399',
    ),
    OfficialPhoneItem(
      id: 'nerima_office',
      titleKo: '네리마 청소사무소 (우편번호 176·179)',
      titleJa: '練馬清掃事務所（郵便番号 176・179）',
      subtitleKo: '네리마, 사쿠라다이, 히카리가오카, 헤이와다이 등',
      subtitleJa: '練馬・桜台・光が丘・平和台・豊玉など担当',
      phone: '03-3992-7141',
    ),
    OfficialPhoneItem(
      id: 'shakujii_office',
      titleKo: '샤쿠지이 청소사무소 (우편번호 177·178)',
      titleJa: '石神井清掃事務所（郵便番号 177・178）',
      subtitleKo: '샤쿠지이, 오이즈미가쿠엔, 후지미다이, 세키마치 등',
      subtitleJa: '石神井・大泉学園・富士見台・関町など担当',
      phone: '03-3928-1353',
    ),
  ];
}
