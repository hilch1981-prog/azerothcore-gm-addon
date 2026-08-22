# 공개 참고 자료

## 주요 참고 저장소

- WOW Legends GM Addon: https://github.com/WOWLegendsHQ/wow-legends-gm-addon
- AzerothCore WotLK: https://github.com/azerothcore/azerothcore-wotlk

## GM 명령 메타데이터 기준

- 기준 커밋: `c143cdaa7cb877d6481a5c941da76b77b9b99165` (2026-08-21 UTC)
- 기준 파일: `data/sql/base/db_world/command.sql`
- 고정 원문 URL과 SHA-256은 `tools/command_metadata_source.json`에 기록한다.
- `tools/audit_command_meta.py`는 공식 기본 명령의 누락과 보안 등급 차이, 승인되지 않은 모듈 명령 혼입을 검사한다.
- `required_module_commands` 41개는 현재 사용자 기준본에 포함된 필수 메타데이터이며, 실제 서버별 모듈 설치 여부와는 별도로 보존한다.
- CI는 고정된 커밋의 원문을 내려받아 검사하므로 AzerothCore의 이후 변경이 예고 없이 현재 빌드를 깨뜨리지 않는다.
- 기준 커밋을 갱신할 때는 URL, SHA-256, 예상 명령 수와 차이 보고서를 함께 검토한다.

## 사용 원칙

- WOW Legends 저장소는 기존 GM 애드온의 구조와 기능을 이해하기 위한 공개 참고 자료로 사용한다.
- AzerothCore 저장소는 GM 명령, 서버 처리, DB 스키마 및 3.3.5a 서버 동작을 확인하는 기준으로 사용한다.
- 참고 저장소의 최신 상태가 현재 사용자 소스와 같다고 가정하지 않는다.
- 사용자 최신 소스와 충돌하면 사용자 소스를 기준으로 차이를 분석하되, 검증되지 않은 동작을 추측하지 않는다.
- 라이선스와 저작권 고지를 확인하고 원문 코드를 가져올 때 해당 조건을 준수한다.

## 퀘스트 보상 데이터 기준

- AzerothCore 기준 커밋: `c143cdaa7cb877d6481a5c941da76b77b9b99165`
- 기준 파일: `data/sql/base/db_world/quest_template.sql`
- `quest_template.sql` SHA-256: `5dc7e6c92ea6875a5fc68cf5d3e33150e86cda5819a11af0c59217b24c63a37f`
- WotLK 3.3.5a Build 12340 `AreaTable.dbc` SHA-256: `eb4bcfa77b03aed853c4783ac260a4259970effaad5b8a74d868783b4dbdc44e`
- `tools/generate_quest_reward_335.py`가 `RewardItem1..4`와 `RewardChoiceItemID1..6`을 분리 수집하고, AreaTable의 MapID 571/530/1/0을 노스렌드/아웃랜드/칼림도어/동부 왕국으로 매핑한다.
- 생성물 `QuestRewards335.lua`에는 원본 커밋과 두 입력 파일의 해시를 기록하며, 실행 시 기존 분류와 중복 없이 병합한다.

## 현재 제공 자료 주의사항

- `WOW_Legends_KR_FULL_ALL_20260813.zip`: 한국어 DB 패치 SQL이며 GM 애드온 소스가 아님
- `지엠커멘드.sql`: AzerothCore 명령 테이블 참고 덤프이며 GM 애드온 소스가 아님
- `GMAddon_335a_AzerothCore_V328_20260818.zip`: 현재 저장소의 `AzerothAdmin/` 소스 기준본
- 기준본 SHA-256: `54A79A0DF20043EBC98615E9F7021751614AA273F41B90FF91E4A7CA17E2972B`
