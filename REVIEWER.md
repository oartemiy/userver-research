# Проверяющему

Все команды выполняются из корня репозитория в подготовленном контейнере.
Хостовые обёртки не нужны.

## Минимальная проверка

1. `make help` — список команд.
2. `make test` — unit-тест и benchmark. Ожидается `2/2` passed.
   `make test-all` — полный ctest; требует PostgreSQL/MongoDB и для задания
   по профилированию сборки не нужен.
3. `make results` — медианы из `results/comparison.md`.
4. `make cba` — краткая выжимка `cba-report.txt` и `cba-report-pch.txt`.

Одной командой: `make verify` — тесты + быстрый замер в `results-quick/`.

## Воспроизведение замеров

* `make measure-quick` — 1 чистая сборка baseline и 1 PCH, пишет в
  `results-quick/`, канонический `results/` не трогает.
* `make measure` — 5 чистых сборок baseline и 5 PCH, пишет в `results/`
  (перезапишет канонические результаты).
* `make results-quick` — показать результат быстрого прогона.

Первый запуск может установить Clang и собрать ClangBuildAnalyzer в
`.tools/ClangBuildAnalyzer`; дальше они переиспользуются.

## Что смотреть

* `results/comparison.md` — медианы frontend/backend/CPU/wall/link.
* `results/summary.json` — те же числа машинно-читаемо.
* `cba-report.txt`, `cba-report-pch.txt` — полные CBA-отчёты канонических
  прогонов.
* `results/<mode>/cba-report-N.txt` — сырые отчёты всех повторов.

## Ожидаемые медианы (5 сборок)

| метрика | baseline | PCH | Δ |
|---|---:|---:|---:|
| frontend, с | 37.9 | 27.5 | −27.4% |
| backend, с | 16.4 | 16.3 | −0.6% |
| CPU, с | 54.3 | 43.8 | −19.3% |
| wall-clock, с | 29.9 | 29.5 | −1.6% |
| линковка, с | 11.88 | 11.87 | 0% |
