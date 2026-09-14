# GM MINI BAR — 리치왕 · AzerothCore v1.0.0

WoW 3.3.5a (12340)용 한국어 GM 애드온입니다. 제작자: **취미연구가**.

**[설치 ZIP 다운로드](https://github.com/hilch1981-prog/azerothcore-gm-addon/releases/latest/download/GMminibar_AzerothCore_3.3.5a_v1.0.0.zip)** · [릴리스 안내](https://github.com/hilch1981-prog/azerothcore-gm-addon/releases/latest)

## 설치

1. 사용하는 게임 버전이 **WoW 3.3.5a (12340)**인지 확인하고 게임을 종료합니다.
2. 위의 설치 ZIP을 풀고 **GMminibar 폴더 하나**를 게임의 `Interface/AddOns`에 복사합니다.
3. 최종 경로가 `Interface/AddOns/GMminibar/GMminibar.toc`인지 확인합니다.
4. 애드온 목록에서 해당 버전의 **GM MINI BAR**를 켠 뒤 캐릭터로 접속합니다.
5. 미니바의 **GM 메뉴** 또는 `/aaac` 명령으로 창을 엽니다.

GitHub가 자동으로 제공하는 **Source code** 파일은 개발용입니다. 일반 설치에는 위의 설치 ZIP 하나를 사용하세요. 기존 다른 GM 애드온과 같은 기능을 중복 사용한다면 해당 애드온을 끄세요. 저장 설정을 유지하려면 `WTF` 폴더를 지우지 않습니다.

이 애드온은 별도 MPQ·DLL·SQL 설치를 요구하지 않습니다. 게임 전체 한글화와 서버 설치 파일은 포함하지 않습니다. GM 명령은 접속한 서버의 권한과 지원 여부에 따라 실행됩니다.

## 주요 기능

- GM 미니바, 이동 손잡이, 크기 조절, 톱니바퀴 설정 버튼
- 아이템 검색·지급, 주문 단계 조회·습득, 전문기술 등급과 제작법 조회
- 습득 상태 표시, 습득 제외 필터, 전문기술의 순차 등급 습득
- 여관·비행경로 NPC, 던전·공격대·전장 입구 순간이동과 즐겨찾기
- 레벨 ±1/±10, 수리, 회복, 부활, 수면 보행 등 GM 편의 기능
- 본인 적용은 왼쪽 클릭, 지원하는 다른 플레이어 적용은 오른쪽 클릭
- 기본 퀘스트 창 옆 도우미와 파티원 적용 옵션
- 통합 가방, 아이템 사용·이동, 장착 가방 4칸, 검색·정렬·고정

순간이동 목록에는 해당 인스턴스가 지원하는 인원수·일반/영웅 난이도를 구분하여 표시합니다. 현재 목적지 목록과 명령은 이 게임 버전의 전용 자료를 사용합니다. 서버 전체 플레이봇 수량 변경은 이 배포본의 지원 기능이 아닙니다.

## 확인 범위

3.3.5a / WOW Legends Repack 1.5.3에서 붉은십자군 수도원·검은심연 나락·울다만·마라우돈·아졸네룹·안카헤트·전쟁노래 협곡 양 진영 입구의 **탈것 출발 및 정상 착지 8건**을 확인했습니다. 아졸네룹과 안카헤트는 공용 만남의 돌 옆 동굴 바닥으로 이동합니다. ASP1.5 자체는 별도로 시험하지 않았습니다.

자동 검사와 실제 게임 확인은 구분합니다. 모든 서버 환경·명령·목적지에 대한 전수 검사를 뜻하지 않습니다. 자세한 내용은 [검증 안내](docs/VALIDATION_KO.md)를 확인하세요.

## 게임 버전별 저장소

| 게임 | 저장소 |
|---|---|
| 리치왕 3.3.5a / AzerothCore | [azerothcore-gm-addon](https://github.com/hilch1981-prog/azerothcore-gm-addon) |
| MoP 5.4.8 / SkyFire 계열 | [mop-gm-addon](https://github.com/hilch1981-prog/mop-gm-addon) |
| Turtle WoW 1.18.1 / Tortoise | [turtle-gm-addon](https://github.com/hilch1981-prog/turtle-gm-addon) |

세 버전은 설치 폴더 이름이 같으므로 **각각 해당 게임 클라이언트에만 설치**합니다. UI 규칙은 공유하지만 코드·명령·데이터·검증은 별도로 관리합니다.

## 개발 및 출처

애드온 소스는 `GMminibar/`, 재현 가능한 ZIP 생성 도구는 `scripts/package.py`에 있습니다. [개발 안내](docs/DEVELOPMENT_KO.md), [출처 및 라이선스](THIRD_PARTY_NOTICES.md)를 참고하세요.
