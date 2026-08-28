# 타사 코드·데이터·애드온 출처 및 라이선스

이 문서는 소스, 번역, 애드온, 라이브러리 또는 데이터 리소스를 참고하거나 포함할 때 출처와 라이선스를 추적하기 위한 기준 문서다.

## 모듈화·다국어 기반 변경

이번 작업에서 새로 작성한 `Framework/`, `Locales/`, 각 `Modules/*/Registration.lua` 및 관련 도구·문서는 이 저장소의 GNU GPL v3 조건에 따라 제공된다.

- 영어·한국어·중국어 간체·번체 기본 UI 문자열은 이번 변경에서 새로 작성했다.
- 외부 번역문이나 기계 번역 데이터 파일을 가져오지 않았다.
- 기존 기능 파일의 모듈 이동은 동일 저장소의 기존 blob을 우선 재사용했다.

### AzerothCore WotLK

- 출처: `https://github.com/azerothcore/azerothcore-wotlk`
- 라이선스: GNU General Public License v2.0
- 사용 범위: WotLK 3.3.5a 서버 명령, DB 스키마, 클라이언트 호환 동작의 검증 기준
- 사용 방식: 호환성 및 명령 동작 검증 기준. 이번 모듈화 작업에서 AzerothCore 코드 파일을 직접 복사하지 않음

### WOW Legends GM Addon

- 출처: `https://github.com/WOWLegendsHQ/wow-legends-gm-addon`
- 저작권: WoW Legends (timoinglin)
- 라이선스: MIT License
- 사용 범위: 기존 GM 애드온 구조를 비교하는 공개 참고 자료
- 사용 방식: 구조 비교 참고. 이번 모듈화 작업에서 코드 파일을 직접 복사하지 않음

### AtlasLootClassic

- 출처: `https://github.com/Hoizame/AtlasLootClassic`
- 라이선스: GNU General Public License v2.0
- 사용 범위: 크리처 브라우저의 던전/레이드 보스 분류와 목록 구성 비교
- 사용 방식: 분류 구조와 대상 목록을 참고해 AzerothAdmin 데이터를 독립 작성. AtlasLootClassic Lua 코드, 이미지 또는 기타 리소스를 이 저장소에 복사하지 않음

## 기존 포함 라이브러리

### LibStub

- 포함 경로: `AzerothAdmin/Embedded/InvenCraftInfo/libs/LibStub/LibStub.lua`
- 원문 고지: Public Domain
- 원저자 표기: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke

### CallbackHandler-1.0 / LibDataBroker-1.1

- 포함 경로: `AzerothAdmin/Embedded/InvenCraftInfo/libs/`
- 현재 포함 파일만으로 독립 재배포 라이선스를 확인하지 못함.
- 재배포 전 upstream 출처와 라이선스를 별도로 확인해야 한다.

### LibItemTooltip-1.0 / LibRaidComm-1.0 / LibMapButton-1.1

- 포함 경로: `AzerothAdmin/Embedded/InvenCraftInfo/libs/`
- 파일에 표시된 제작자: Inven / InTheBlue 또는 intheblue
- 현재 포함 파일만으로 명시적인 재배포 라이선스를 확인하지 못함.
- 출처와 재배포 허용 조건을 확인하기 전에는 별도 프로젝트로 복사하거나 재라이선스하지 않는다.

## 추가 리소스 도입 규칙

새 리소스를 추가하거나 동작·구조를 참고하는 PR에는 다음을 반드시 기록한다.

- 프로젝트명과 원저작자
- 원본 저장소 또는 배포 주소
- 라이선스명과 라이선스 원문 위치
- 가져온 파일 또는 참고한 범위
- 원본 사용, 수정, 번역, 재구성 또는 동작 참고 여부
- 필요한 저작권 및 NOTICE 유지 여부

출처 또는 라이선스를 확인할 수 없는 리소스는 배포본에 새로 포함하지 않는다.
