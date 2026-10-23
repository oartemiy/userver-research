# Baseline vs PCH (median of repeated clean builds)

Runs: baseline=5, pch=5. Each run is a clean configure + `ninja research` with `-ftime-trace`. Frontend/backend are CBA sums over all traced compilations, including the 3 PCH builds in the PCH mode.

| metric | baseline | PCH | delta |
|---|---:|---:|---:|
| TUs compiled (incl. PCH) | 10 | 13 | +3 |
| frontend, s | 37.9 | 27.5 | -10.4 (-27.4%) |
| backend, s | 16.4 | 16.3 | -0.1 (-0.6%) |
| compile CPU total, s | 54.3 | 43.8 | -10.5 (-19.3%) |
| wall clock, s | 29.9 | 29.5 | -0.5 (-1.6%) |

## Build phases from .ninja_log (median, ms)

| phase | baseline | PCH | delta |
|---|---:|---:|---:|
| protobuf/gRPC codegen finished at | 838.0 | 825.0 | -13.0 (-1.6%) |
| compilation finished at | 18063.0 | 17449.0 | -614.0 (-3.4%) |
| link `research` | 11876.0 | 11873.0 | -3.0 (-0.0%) |
| build total | 29799.0 | 29322.0 | -477.0 (-1.6%) |

## Per-run wall clock, s

| run | baseline | pch |
|---|---:|---:|
| 1 | 30.12 | 29.00 |
| 2 | 30.13 | 28.78 |
| 3 | 29.94 | 29.46 |
| 4 | 29.88 | 31.59 |
| 5 | 29.49 | 29.69 |

## Translation units by frontend time (median, ms)

| TU | baseline | PCH | delta |
|---|---:|---:|---:|
| `src/main.cpp` | 6562.2 | 4037.5 | -2524.7 (-38.5%) |
| `proto/handlers/hello_client.usrv.pb.cpp` | 5110.2 | 3266.5 | -1843.7 (-36.1%) |
| `proto/handlers/hello_service.usrv.pb.cpp` | 5076.2 | 3181.0 | -1895.2 (-37.3%) |
| `src/hello_postgres.cpp` | 4139.2 | 2215.8 | -1923.4 (-46.5%) |
| `src/hello_grpc.cpp` | 3789.8 | 2443.8 | -1346.1 (-35.5%) |
| `proto/handlers/hello.grpc.pb.cc` | 3687.5 | 1570.4 | -2117.1 (-57.4%) |
| `src/hello_mongo.cpp` | 3132.0 | 530.5 | -2601.5 (-83.1%) |
| `src/hello.cpp` | 2657.0 | 324.2 | -2332.8 (-87.8%) |
| `proto/handlers/hello.pb.cc` | 2210.8 | 687.6 | -1523.2 (-68.9%) |
| `src/greeting.cpp` | 1592.4 | 401.0 | -1191.4 (-74.8%) |
| `cmake_pch.hxx [research]` | n/a | 3124.8 | n/a |
| `cmake_pch.hxx [research_objs]` | n/a | 3109.5 | n/a |
| `cmake_pch.hxx [research_proto]` | n/a | 2527.3 | n/a |

## Top headers by inclusive parse time (median, ms)

| header | baseline | PCH |
|---|---:|---:|
| `proto/handlers/hello_service.usrv.pb.hpp` | 6040.0 | 5253.0 |
| `userver/components/component.hpp` | 5226.0 | n/a |
| `src/hello_postgres.hpp` | 4385.0 | 2617.0 |
| `src/hello_grpc.hpp` | 4354.0 | 3491.0 |
| `proto/handlers/hello.pb.h` | 4234.0 | 560.0 |
| `proto/handlers/hello_client.usrv.pb.hpp` | 3520.0 | 1864.0 |
| `src/hello_mongo.hpp` | 2791.0 | n/a |
| `src/hello.hpp` | 2431.0 | n/a |
| `userver/clients/dns/component.hpp` | 2174.0 | n/a |
| `fmt/format.h` | 1625.0 | n/a |
