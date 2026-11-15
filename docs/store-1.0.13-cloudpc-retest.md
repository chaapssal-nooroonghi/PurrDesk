# 집사 옆자리 1.0.13.0 — 검사 세션 전달문

2026-11-15 KST. **빌드 환경 검사는 통과. 실제 Cloud PC UI 재검사는 아직 하지 않았으며 심사에 제출하지 않았다.**

## 받을 파일

- [로그인 없이 수정본 ZIP 받기](https://nightly.link/chaapssal-nooroonghi/PurrDesk/actions/runs/43699245732/store-v113-validation.zip)
- [Actions 원본 실행](https://github.com/chaapssal-nooroonghi/PurrDesk/actions/runs/43699245732)
- Artifact: `store-v113-validation` (ID `14155980826`, 보존 30일)
- commit: `c0576a8a289b5abffcb4cea5fc542489f88a7863`
- MSIX: `Jipsa-Yeopjari-1.0.13.0-Store.msix`
- MSIX 버전: **1.0.13.0**, 크기 **25,531,216 bytes** (v112보다 285 bytes 증가)
- MSIX SHA256: `e475966fb2655a2d327260c7c556b63b01c134863683065e27d702a5e91888d0`
- ZIP: 26,051,880 bytes, SHA256 `2f8106eaee489a44e9eef388cf9deb1592c6426daa9cf3ce1d7cbe9c22cfcef3`

[수정 전후 비교 원본 ZIP](https://nightly.link/chaapssal-nooroonghi/PurrDesk/actions/runs/43699228758/store-v113-ui-comparison.zip) · [비교 Actions](https://github.com/chaapssal-nooroonghi/PurrDesk/actions/runs/43699228758)

## 빌드 환경 결과

| 검사 | 결과 |
|---|---|
| 실제 Windows CI 설치·AUMID 실행 | 통과, 창 2개, PMv2 유지 |
| WACK 10.0.26100.9457 | **24 PASS / 0 FAIL / 0 WARNING**, 전체 PASS, PARTIAL_RUN=FALSE, APP_VERSION=1.0.13.0 |
| 기존 기본 기능 | 160개 통과 |
| 저장·보정·EXIF 회귀 | 25개 통과 |
| 폼 글꼴/DPI 메시지 시나리오 | 72개 통과 |
| 메뉴 재사용 시나리오 | 28개 통과 |
| 추가 레이아웃·귀염둥이 크기 독립성 | 35개 통과 (동일 검사 v112는 28 PASS / 7 FAIL) |
| 실제 Cloud PC 화면 배율 변경·로그아웃 후 자동 시작 | **이번 빌드 환경에서 미검사**, 아래 절차로 재검증 필요 |

ZIP의 `wack-report.xml`은 편집하지 않은 이번 CI 검사 원본이다. SHA256 `2ed66e55b6c5e821e9b7e7a4526df47fa320d3afce4c4d5e1b88226193aa3b16`. Cloud PC WACK 10.0.28000.2957 결과와 구분한다. `runtime.json`, 각 검사 로그, `REVIEW.ko.md`, `source-changes.patch`, `source-sha256.json`, `LayoutChecks.cs`가 동봉되어 있다.

MSIX를 v112와 전 항목 비교했다. 바뀐 항목은 `PurrDesk.exe`, 버전이 바뀐 `AppxManifest.xml`, `AppxBlockMap.xml`뿐이다. 기존 모델·사진·DLL·앱 설정은 모두 바이트 단위 동일. 원본 MSIX에 테스트 서명/인증서/키 없음. 패키지 Name/Publisher/PublisherDisplayName/Product ID 유지. 기존 v1.0.5 및 Mac 배포 변경 없음.

실제 Cloud PC의 v112 원본 보고서 ZIP은 Mac에 보존된 별도 파일이며 이 빌드 세션에서는 열지 못했다. 사용자가 전달한 재현 절차와 보고서 본문으로 조사했다. 그 원본 화면이나 XML을 새로 직접 검증했다고 주장하지 않는다.

심사 제출 금지. 수정본의 UI 문제 해결 및 새 버전 설치/실행/실제 재로그인 자동 시작/WACK까지 검사한 뒤 사용자에게 결과를 보고한다. 현재 유지 중인 Cloud PC 앱·테스트 인증서·임시 관리자·전원은 최신 사용자 지시 없이 변경하거나 정리하지 않는다.

## 사용자 요구 확인

귀염둥이 크기(50/65/100/150%)를 바꿔도 설정창과 우클릭 메뉴의 크기·폰트는 달라지지 않는다. Windows 화면 배율은 별개이며 PMv2 확대를 계속 지원한다. 설정창을 물리적 100% 크기에 고정하라는 요청이 아니다.

## 패키지와 증거

이번 Store 전용 후보 버전은 1.0.13.0. 원본 MSIX에는 서명·임시 인증서·개인키를 넣지 않았다. 이전 v1.0.5/Mac 릴리스는 유지한다. 변경은 Windows UI 소스 다섯 파일뿐이다. REVIEW.ko.md / source-changes.patch / source-sha256.json을 참고한다.

최종 빌드 ZIP에는 원본 WACK XML, runtime.json, 회귀 검사 로그와 코드가 들어 있다. 별도 전후 비교 ZIP은 1.0.12 원본 EXE와 동일 검사기를 실행한 결과다. 이전 버전 28 PASS/7 FAIL, 수정본 35 PASS/0 FAIL. '실제 Cloud PC 배율 전환 통과'를 뜻하지 않는다.

## 최우선 — 실제 스트레칭 잘림

1. 원본 MSIX 해시를 대조하고, 현재 AppData의 전체 설정/사진 경로·크기·SHA256 목록을 백업한다. v112 원본 사진 27개와 추가 합성 EXIF 사진 1개를 구분한다. 사용자 설정·사진을 초기화하지 않는다.
2. 원본을 복사한 파일만 테스트 서명해 기존 v112 위에 업데이트 설치한다. 기존 설치·신뢰 상태를 먼저 확인하고 불필요한 인증서를 추가하지 않는다.
3. 실제 Windows 200%에서 새 StretchForm을 연다. '스트레칭 알림 켜기' 전체 문구, 글꼴, 컨트롤 실제 bounds, HWND DPI192, PMv2, MonitorScale200을 기록한다.
4. 창을 유지한 채 실제 150→200%를 수행한다. 첫 화면/드래그 후/재오픈 화면을 캡처한다. 전체 문구가 보이는지 비교하고 동일 DPI에서 새 창과 열린 창의 글꼴 픽셀 크기·글자 영역·체크박스 폭을 기록한다.
5. 새 프로세스에서 125→150→200%도 같은 방식으로 검사한다. 기존에 재현한 두 경로를 모두 확인한다.
6. 실패하면 즉시 native DPI/monitor scale 및 화면을 보존한다. 계측 가능하면 WM_DPICHANGED, 자식 BEFOREPARENT/AFTERPARENT, 마지막 레이아웃 시점의 글꼴·Font.Unit·Bounds·Padding·Margin·GetPreferredSize 결과를 순서대로 남긴다. 한글 UIA Name이 손상되면 원본 스크린샷을 문구 근거로 쓴다.

빌드 환경에서는 부모 DPI 메시지만 주면 기존 v112도 잘림 검사에 통과했다. '자식 DPI 처리 완료 전에 좁은 bounds가 남는 상황'을 시험용으로 만든 검사는 수정 전 실패/수정 후 통과하지만 원격 환경의 진짜 메시지 순서를 재현하지 않는다. 따라서 이 단계의 실제 재현 해소를 반드시 확인해야 한다.

## 사진 관리창과 공통 폼

- 실제 250%에서 새 프로세스의 PhotoLibraryForm과 여러 배율 전환 후 같은 프로세스에서 새로 연 창을 비교한다. 창·버튼·폰트·문구가 정상 비율인지 확인한다. 사진 추가/선택/목록 적용/취소도 수행한다.
- 100/125/150/200/250%에서 SettingsForm 네 탭, StretchForm, PomodoroForm, SizeForm, PhotoLibraryForm, MakeForm, RetouchForm을 확인한다. 창보다 큰 내용은 스크롤해 확인한다.
- 변경 전 저장하지 않은 이름·크기·사진 목록을 유지하고 배율 변경/취소/재오픈을 검사한다.
- 이번 패치는 PhotoLibraryForm의 96 DPI 디자인 기준 누락을 수정했다. MakeForm/RetouchForm은 비교 검사에서 정상이라 변경하지 않았다.

## 트레이 위치 — 원격 좌표와 구별

- 250%에서 트레이 메뉴/하위 메뉴를 열고 닫은 다음 실제100%로 내린다. 첫 팝업과 즉시 두 번째 팝업을 캡처한다.
- 가능하면 클릭 직전 GetCursorPos의 물리 좌표, 트레이 아이콘 사각형, 팝업의 실제 WindowRect를 함께 기록한다. 첫/두 번째 입력 좌표가 같은지 확인한다.
- 테스트는 메뉴 크기 계산을 OnOpening 이전으로 옮겨 오래된 큰 메뉴 크기로 위치를 정하던 앱 경로를 수정했다. 동일 물리 anchor를 직접 사용한 Windows 비교 검사에서 이전 버전 첫 좌표 (0,212) / 두 번째 (325,436), 수정본은 둘 다 (325,436)였다.
- 이 좌표는 CI 예시이며 Cloud PC 기대 좌표가 아니다. 원격 브라우저의 좌표 매핑은 별도로 판단한다. 메뉴 글꼴과 하위 메뉴 위치도 확인한다.

## 귀염둥이 크기 독립성 / 기존 기능

- 같은 Windows 배율에서 귀염둥이 크기를 50→65→100→150%로 바꿔 실제 사진만 크기가 바뀌는지 확인한다. 설정창 및 우클릭 메뉴의 외곽 크기·글꼴은 동일해야 한다. 두 귀염둥이 모두 검사한다.
- 드래그/숨기기/단축키/클릭 통과 해제, 뽀모도르/스트레칭/퇴근 시간 표시, 사진 취소/저장 보존, EXIF 사진 방향, 보정 지우기/복원/되돌리기를 확인한다.
- 설정 저장 중 닫기는 Windows 자동 실행 응답이 빨라 해당 경로를 못 관찰할 수 있다. NOT_OBSERVED를 PASS로 바꾸지 않는다.
- 종료/재실행 및 실제 로그아웃/재로그인 자동 시작을 확인한다. 수동 실행 없이 새 프로세스와 두 창이 뜨는지 기록한다.

## WACK / 결과 전달

- Cloud PC SDK/WACK 10.0.28000.2957에서 appcert.exe reset 후 appcert.exe test -appxpackagepath <서명한 복사본> -reportoutputpath <새 XML> 실행.
- 원본 XML의 APP_VERSION=1.0.13.0 / PARTIAL_RUN=FALSE / 전체 TEST24개 및 OVERALL_RESULT를 확인한다. 종료 코드만으로 판정하지 않는다.
- WindowsApps ACL, WACK 항목/결과, 보안 컨텍스트를 바꾸지 않는다.
- 데이터와 원본 MSIX 해시를 다시 비교한다. 테스트 사진/위치 변경은 따로 기록한다.
- 보고서·원본 XML·로그·화면·해시 목록을 묶되 MSIX/인증서/개인키/토큰/사용자 사진 원본은 제외한다. 현재 환경 보존/정리는 최신 사용자 지시를 따른다.
- 결과가 모두 확인되기 전 심사에 제출하지 않는다.
