AzerothAdminEasy = AzerothAdminEasy or {}
local addon = AzerothAdminEasy

-- Curated navigation data for the creature browser.  This intentionally does
-- not duplicate the full creature_template/koKR catalog in KoKRSearchData.lua.
-- Instance and raid encounters are marked as restricted because their AI can
-- depend on map, instance, encounter or zone scripts at the original location.
addon.FeaturedCreatureCategories = {
    { key = "favorite", label = "★ 즐겨찾기" },
    { key = "all", label = "주요 크리처 전체" },
    { key = "raid", label = "레이드 보스" },
    { key = "raid_classic", label = "   └ 클래식", parent = "raid", expansion = "classic" },
    { key = "raid_tbc", label = "   └ 불타는 성전", parent = "raid", expansion = "tbc" },
    { key = "raid_wotlk", label = "   └ 리치 왕의 분노", parent = "raid", expansion = "wotlk" },
    { key = "dungeon", label = "던전 최종 보스" },
    { key = "world", label = "월드 보스" },
    { key = "leader", label = "주요 NPC·지도자" },
}

addon.FeaturedCreatureExpansionLabels = {
    classic = "클래식",
    tbc = "불타는 성전",
    wotlk = "리치 왕의 분노",
}

addon.FeaturedCreatureGroupLabels = {
    raid = "레이드 보스",
    dungeon = "던전 최종 보스",
    world = "월드 보스",
    leader = "주요 NPC·지도자",
}

addon.FeaturedCreatures = {
    -- Classic raids
    { 10184, "오닉시아", "raid", "classic", "오닉시아의 둥지", true },
    { 11502, "라그나로스", "raid", "classic", "화산 심장부", true },
    { 11583, "네파리안", "raid", "classic", "검은날개 둥지", true },
    { 15727, "쑨", "raid", "classic", "안퀴라즈 사원", true },

    -- The Burning Crusade raids
    { 15690, "공작 말체자르", "raid", "tbc", "카라잔", true },
    { 17257, "마그테리돈", "raid", "tbc", "마그테리돈의 둥지", true },
    { 17968, "아키몬드", "raid", "tbc", "하이잘 산 전투", true },
    { 19044, "용 학살자 그룰", "raid", "tbc", "그룰의 둥지", true },
    { 19622, "캘타스 선스트라이더", "raid", "tbc", "폭풍우 요새", true },
    { 21212, "여군주 바쉬", "raid", "tbc", "불뱀 제단", true },
    { 22917, "일리단 스톰레이지", "raid", "tbc", "검은 사원", true },
    { 25315, "킬제덴", "raid", "tbc", "태양샘 고원", true },

    -- Wrath of the Lich King raids
    { 15990, "켈투자드", "raid", "wotlk", "낙스라마스", true },
    { 28859, "말리고스", "raid", "wotlk", "영원의 눈", true },
    { 28860, "살타리온", "raid", "wotlk", "흑요석 성소", true },
    { 32871, "관찰자 알갈론", "raid", "wotlk", "울두아르", true },
    { 33288, "요그사론", "raid", "wotlk", "울두아르", true },
    { 34564, "아눕아락", "raid", "wotlk", "십자군의 시험장", true },
    { 36597, "리치 왕", "raid", "wotlk", "얼음왕관 성채", true },
    { 36612, "군주 매로우가르", "raid", "wotlk", "얼음왕관 성채", true },
    { 36678, "교수 퓨트리사이드", "raid", "wotlk", "얼음왕관 성채", true },
    { 36853, "신드라고사", "raid", "wotlk", "얼음왕관 성채", true },
    { 37955, "피의 여왕 라나텔", "raid", "wotlk", "얼음왕관 성채", true },
    { 39863, "할리온", "raid", "wotlk", "루비 성소", true },

    -- Selected dungeon final bosses; ordinary and intermediate creatures stay
    -- available only through the existing full koKR/Entry search.
    { 23954, "약탈자 잉그바르", "dungeon", "wotlk", "우트가드 성채", true },
    { 26533, "말가니스", "dungeon", "wotlk", "옛 스트라솔름", true },
    { 26632, "예언자 타론자", "dungeon", "wotlk", "드락타론 성채", true },
    { 26723, "케리스트라자", "dungeon", "wotlk", "마력의 탑", true },
    { 26861, "왕 이미론", "dungeon", "wotlk", "우트가드 첨탑", true },
    { 27656, "지맥 수호자 에레고스", "dungeon", "wotlk", "마력의 눈", true },
    { 27978, "무쇠구체자 쇼니르", "dungeon", "wotlk", "돌의 전당", true },
    { 28923, "로켄", "dungeon", "wotlk", "번개의 전당", true },
    { 29120, "아눕아락", "dungeon", "wotlk", "아졸네룹", true },
    { 29306, "갈다라", "dungeon", "wotlk", "군드락", true },
    { 29311, "사자 볼라즈", "dungeon", "wotlk", "안카헤트: 고대 왕국", true },
    { 31134, "시아니고사", "dungeon", "wotlk", "보랏빛 요새", true },
    { 35451, "흑기사", "dungeon", "wotlk", "용사의 시험장", true },
    { 36502, "영혼의 포식자", "dungeon", "wotlk", "영혼의 제련소", true },
    { 36658, "스컬지군주 티라누스", "dungeon", "wotlk", "사론의 구덩이", true },

    -- Outdoor world bosses.  They are still flagged because world AI may rely
    -- on the original zone even though no instance map is involved.
    { 6109, "아주어고스", "world", "classic", "아즈샤라", true },
    { 12397, "군주 카자크", "world", "classic", "저주받은 땅", true },
    { 14887, "이손드레", "world", "classic", "에메랄드의 꿈 차원문", true },
    { 14888, "레손", "world", "classic", "에메랄드의 꿈 차원문", true },
    { 14889, "에메리스", "world", "classic", "에메랄드의 꿈 차원문", true },
    { 14890, "타에라", "world", "classic", "에메랄드의 꿈 차원문", true },
    { 17711, "파멸의 절단기", "world", "tbc", "어둠달 골짜기", true },
    { 18728, "파멸의 군주 카자크", "world", "tbc", "지옥불 반도", true },

    -- Major city and story NPCs.  These do not receive an automatic
    -- region-script warning, but permanent creation still requires confirmation.
    { 3057, "케른 블러드후프", "leader", "classic", "썬더 블러프", false },
    { 4949, "스랄", "leader", "classic", "오그리마", false },
    { 4968, "여군주 제이나 프라우드무어", "leader", "classic", "테라모어 섬", false },
    { 7937, "땜장이왕 멕카토크", "leader", "classic", "아이언포지", false },
    { 7999, "티란데 위스퍼윈드", "leader", "classic", "다르나서스", false },
    { 10181, "여군주 실바나스 윈드러너", "leader", "classic", "언더시티", false },
    { 16802, "로르테마르 테론", "leader", "tbc", "실버문", false },
    { 17468, "예언자 벨렌", "leader", "tbc", "엑소다르", false },
    { 29611, "국왕 바리안 린", "leader", "wotlk", "스톰윈드", false },
}
