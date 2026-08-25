# AzerothAdmin 프로젝트 사이트

`site/`는 AzerothAdmin GM Addon 소개 및 배포 안내용 정적 사이트다.

## 구성

- `index.html`: 프로젝트 소개, 기능, 설치, 검증 상태, 개발 흐름
- `styles.css`: 다크 + 골드 반응형 UI
- `app.js`: 모바일 메뉴와 설치 경로 복사 기능

별도 빌드 도구나 프레임워크가 필요하지 않으며 정적 파일만으로 동작한다.

## 로컬 확인

`site/index.html`을 브라우저에서 직접 열거나 간단한 로컬 HTTP 서버에서 `site/`를 문서 루트로 사용한다.

## GitHub Pages 배포

`.github/workflows/deploy-site.yml`이 `main`의 `site/**` 변경을 GitHub Pages로 배포한다.

저장소에서 처음 한 번 다음 설정이 필요하다.

1. GitHub 저장소의 **Settings** 이동
2. **Pages** 선택
3. **Build and deployment > Source**를 **GitHub Actions**로 선택
4. 사이트 PR을 검토하고 `main`에 병합
5. `Deploy project site` 워크플로 성공 여부 확인

현재 프로젝트 규칙에 따라 이 사이트 변경도 `main`에 직접 푸시하지 않고 PR로 병합한다.

## 콘텐츠 원칙

- 저장소의 `PROJECT_STATUS.md`, `TASKS.md`, `FEATURE_MAP.md`에 근거한 기능만 표시한다.
- 정적 검증과 실제 게임 내 검증을 구분한다.
- 게임 내 검증이 없는 기능을 완료 상태로 표현하지 않는다.
- WoW/AzerothCore 호환성 표기는 프로젝트의 실제 개발 기준을 따른다.
