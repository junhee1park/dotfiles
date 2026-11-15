# Neovim 키맵·플러그인 재검토 인계

## 진행 방식

- 사용자와 한국어로 대화한다. 한 번에 발견 사항 하나만 설명하고 결정받는다.
- 질문에는 답만 한다. 설계 선택과 구현 승인은 구분하고, 수정 전에 구체적인 변경 범위를 확인받는다.
- 실제 사용 여부를 먼저 확인한다. 기존 키가 있다는 이유로 이전하거나 유지하지 않는다.
- 키맵뿐 아니라 플러그인 조합도 재검토한다. Neovim 내장 기능과 이미 설치된 플러그인으로 대체 가능한지 먼저 확인한다.
- 플러그인 비교는 관리 상태, 채택 규모, 실제 기능을 함께 본다. 공식 문서나 실제 소스를 확인하고 파일:줄을 제시한다.
- 가장 단순한 해법을 사용한다. 목록을 임의로 채우거나 전면 재배치하지 않는다.
- 모든 산문 응답 끝에 별도 `---` / `📝 English` 블록을 붙인다. 한국어 메시지는 자연스러운 영어 표현으로, 영어 메시지는 교정과 자연스러운 표현으로 피드백한다. 단순 동의 같은 짧은 메시지는 생략 가능.

## 키 설계 원칙

- 표면 진입은 전역 leader, 표면 내부 동작은 버퍼 로컬 단일 키, 전역 동작은 도메인 그룹, 이동·토글은 `[`/`]`와 `\`를 사용한다.
- 그룹 이름은 플러그인 이름보다 누르기 직전 떠오르는 명사에서 정한다.
- 그룹은 멤버 3개 이상일 때 만든다. 짧은 진입점은 실제 빈도로 정한다.
- Shift는 같은 동작의 범위 변경을 뜻한다.

## 완료한 변경

- mini.pick을 Telescope + telescope-fzf-native.nvim으로 교체했다.
- 사용자가 고른 다섯 기능만 남겼다: 파일, 내용 검색, 열린 버퍼, 최근 파일, 도움말.
- `nvim/lua/plugins/telescope.lua`:
  - `<leader><leader>` / `ff`: find_files
  - `<leader>/` / `fg`: live_grep
  - `fb`: buffers
  - `fh`: help_tags
  - `fr`: oldfiles, 프로젝트 전체 최근 기록. fv/fV의 범위 구분은 사용자가 불필요하다고 판단해 제거.
  - fzf-native는 make로 빌드하고 확장을 로드한다. 매칭 옵션은 기본값.
  - horizontal.preview_cutoff = 0으로 좁은 창에서도 프리뷰를 표시한다.
  - 내부 키는 Telescope 기본값. 전역 ff/fg/fb/fh는 공식 README 예제와 같다.
- mini.pick의 모든 Pick 키, 붙여넣기 보정, ai.lua의 MiniPickStart 창 보정을 제거했다. lockfile도 갱신했다.
- mini.extra는 유지한다. mini.ai의 전체 버퍼 텍스트 객체가 MiniExtra.gen_ai_spec.buffer()를 쓴다.
- mini.visits는 아직 남아 있다. 제거 여부는 따로 결정하지 않았다.
- find 그룹 이름을 +file에서 +find로 변경했다.
- 사용하지 않는 fn(:enew)과 ot(trim trailing whitespace) 키 및 +other 그룹 표시를 제거했다.
- mini.trailspace는 공백 강조를 위해 유지했다.
- scripts/dev/neovim.sh의 ripgrep 설치 안내를 Telescope로 수정했다. brew install ripgrep은 기존부터 있었다.
- Telescope 프리뷰는 기본적으로 직접 포커스해 탐색하는 흐름이 없다. Snacks는 Alt-w로 input → preview → list를 순환하고 preview의 i로 입력창에 복귀한다. 사용자는 이 차이를 확인한 뒤에도 Telescope로 결정했다.
- :Lazy clean은 실행하지 않았다. 제거된 플러그인 디렉터리가 디스크에 남아 있을 수 있다.

## 이전 세션에서 이미 커밋된 변경

- bc66a7e: mini.files를 neo-tree로 교체.
- 76e28c8: mini.bracketed를 제거하고 Neovim 내장 bracket 키를 사용.
- 2a2efd8, 0e401a0: 자동 변경 설정 ignore 및 Rex 세션 자동 이름 비활성화.
- mini.clue는 유지하기로 결정했다. which-key로 교체하지 않는다.

## 지금 멈춘 지점: 터미널 사용 경험 질문

다음 항목인 t 그룹과 터미널 플러그인 구성을 조사했고, 아직 수정하지 않았다.

현재 nvim/lua/plugins/snacks.lua:

| 키 | 처음 만들 때 위치 |
|---|---|
| Ctrl-/ (Ctrl-_ 인코딩도 연결) | 아래 |
| <leader>tt | 오른쪽 |
| <leader>tT | 아래 |

Snacks terminal의 ID는 cmd, cwd, env, count로 결정된다. win.position은 포함하지 않는다.
따라서 같은 조건에서는 위 키가 모두 같은 셸 터미널을 토글한다. tt 후 tT를 눌러도 위치를 바꾸는 것이 아니다.
근거: 설치된 snacks.nvim/lua/snacks/terminal.lua의 M.tid, M.get, M.toggle(조사 당시 176줄 이후).
셸 실행은 Neovim 내장 terminal이 담당하고 Snacks가 재사용·숨기기·표시를 관리한다.
Sidekick AI 터미널도 있지만 별개 용도이므로 함께 제거하지 않는다.

**사용자에게 마지막으로 한 질문(미응답):**
“Neovim 안의 셸 터미널을 실제로 쓰시나요? 쓴다면 주로 Ctrl-/, tt, tT 중 어느 키로 여시나요? tmux나 Ghostty에서만 쓰신다면 그것도 판단 기준입니다.”

새 세션은 이 질문부터 이어간다. 사용자에게 사용 경험을 확인하기 전 키를 임의로 정리하지 않는다.

## 이후 계획

1. 터미널 사용 방식 확인 후 t 그룹/중복 진입점 및 플러그인 필요성 판단.
2. e 그룹: neo-tree / 알림 / quickfix가 섞여 있는 구조 검토.
3. Git: 남은 git 명령, gitsigns, lazygit 역할·진입점 중복 검토. 예전 fa picker는 이미 제거되어 예전 목록을 그대로 쓰면 안 된다.
4. ld 진단 팝업과 내장 Ctrl-W d 중복, 저빈도 Lazy의 leader L 자리 등 하나씩 검토.
5. 전체 잔여 참조, 충돌, mini.clue 설명, 실제 동작 점검. 다른 미사용 플러그인도 사용 여부를 확인한 뒤 제안.

## 검증과 주의점

- 이 Mac에서 Telescope 및 fzf-native 설치·빌드를 완료했다. 다른 컴퓨터는 :Lazy install로 설치하고 make/C 컴파일러 및 rg를 확인해야 한다.
- headless로 다섯 picker를 실제로 열어 결과와 프리뷰를 확인했고 native sorter 매칭도 실행했다. mini.pick 미설정·미로드, :Pick 부재, mini.extra 버퍼 텍스트 객체도 확인했다.
- 이후 fr 매핑과 fv/fV 미등록을 확인했다. git diff --check와 zsh -n scripts/dev/neovim.sh 통과.
- headless에서는 VeryLazy가 발생하지 않을 수 있으므로 require("config.keymaps")를 직접 호출한다.
- keys 기반 lazy 플러그인은 require("lazy").load({ plugins = { "telescope.nvim" } })로 로드한다.
- oldfiles는 현재 파일을 제외하므로 테스트 기록에 현재 파일 하나만 넣으면 결과가 없다.
- nvim 옵션/캐시/플러그인 설치는 홈 경로 쓰기가 필요하다. headless 실행 실패 시 exit code만 보지 말고 오류 출력을 확인한다.
- prefs/는 도구 출력 스냅샷으로 수동 편집하지 않는다.
- 이번에는 사용자가 명시적으로 다른 컴퓨터 인계를 위한 새 브랜치·커밋·새 세션을 요청했다. 이전의 main 직접 커밋 관행보다 이 요청이 우선한다.
