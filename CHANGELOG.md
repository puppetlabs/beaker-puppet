# Changelog

All notable changes to this project will be documented in this file.

## [1.29.0](https://github.com/voxpupuli/beaker-puppet/tree/1.29.0) (2022-11-02)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.28.0...1.29.0)

**Implemented enhancements:**

- Introduce BEAKER\_PUPPET\_DEBUG env var [\#197](https://github.com/voxpupuli/beaker-puppet/pull/197) ([ekohl](https://github.com/ekohl))

**Fixed bugs:**

- \(maint\) Fix DigiCert root cert to match fully patched Solaris 11.4 [\#202](https://github.com/voxpupuli/beaker-puppet/pull/202) ([yachub](https://github.com/yachub))

**Merged pull requests:**

- \(maint\) Uses RFC 5737 IP space in example [\#200](https://github.com/voxpupuli/beaker-puppet/pull/200) ([mhashizume](https://github.com/mhashizume))

## [1.28.0](https://github.com/voxpupuli/beaker-puppet/tree/1.28.0) (2022-09-08)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.27.0...1.28.0)

**Implemented enhancements:**

- \(PA-4552\) Create ci:test:setup step for iterative workflow [\#194](https://github.com/voxpupuli/beaker-puppet/pull/194) ([joshcooper](https://github.com/joshcooper))

## [1.27.0](https://github.com/voxpupuli/beaker-puppet/tree/1.27.0) (2022-08-31)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.26.3...1.27.0)

**Implemented enhancements:**

- \(ITSYS-2543\) Adds workaround for EL8 PPCLE [\#198](https://github.com/voxpupuli/beaker-puppet/pull/198) ([mhashizume](https://github.com/mhashizume))

**Fixed bugs:**

- \(PA-4566\) Retry beaker exec if presuite completes [\#195](https://github.com/voxpupuli/beaker-puppet/pull/195) ([joshcooper](https://github.com/joshcooper))

**Merged pull requests:**

- Release 1.27.0 [\#199](https://github.com/voxpupuli/beaker-puppet/pull/199) ([mhashizume](https://github.com/mhashizume))

## [1.26.3](https://github.com/voxpupuli/beaker-puppet/tree/1.26.3) (2022-08-09)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.26.2...1.26.3)

**Fixed bugs:**

- Actually print the versions.txt file [\#193](https://github.com/voxpupuli/beaker-puppet/pull/193) ([joshcooper](https://github.com/joshcooper))

**Merged pull requests:**

- Release 1.26.3 [\#196](https://github.com/voxpupuli/beaker-puppet/pull/196) ([joshcooper](https://github.com/joshcooper))

## [1.26.2](https://github.com/voxpupuli/beaker-puppet/tree/1.26.2) (2022-05-31)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.26.1...1.26.2)

**Merged pull requests:**

- \(PA-4178\) Only clear and add non-default gem sources [\#190](https://github.com/voxpupuli/beaker-puppet/pull/190) ([joshcooper](https://github.com/joshcooper))

## [1.26.1](https://github.com/voxpupuli/beaker-puppet/tree/1.26.1) (2022-03-24)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.26.0...1.26.1)

**Implemented enhancements:**

- \(maint\) Adds CA to Solaris 11 SPARC setup [\#186](https://github.com/voxpupuli/beaker-puppet/pull/186) ([mhashizume](https://github.com/mhashizume))

**Fixed bugs:**

- \(maint\) Fixes Solaris cert setup step [\#188](https://github.com/voxpupuli/beaker-puppet/pull/188) ([mhashizume](https://github.com/mhashizume))

**Merged pull requests:**

- \(PA-4332\) Changes download links to HTTPS [\#185](https://github.com/voxpupuli/beaker-puppet/pull/185) ([mhashizume](https://github.com/mhashizume))

## [1.26.0](https://github.com/voxpupuli/beaker-puppet/tree/1.26.0) (2022-03-23)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.25.0...1.26.0)

## [1.25.0](https://github.com/voxpupuli/beaker-puppet/tree/1.25.0) (2022-03-16)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.24.0...1.25.0)

**Implemented enhancements:**

- \(PA-4331\) Add a step for updating Solaris CA Keystore [\#182](https://github.com/voxpupuli/beaker-puppet/pull/182) ([cthorn42](https://github.com/cthorn42))

**Fixed bugs:**

- \(PA-4331\) Fix the logic to only run on older solaris versions [\#183](https://github.com/voxpupuli/beaker-puppet/pull/183) ([cthorn42](https://github.com/cthorn42))

## [1.24.0](https://github.com/voxpupuli/beaker-puppet/tree/1.24.0) (2022-03-04)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.23.0...1.24.0)

**Implemented enhancements:**

- module setup on the target: Ignore files at the root level only [\#177](https://github.com/voxpupuli/beaker-puppet/pull/177) ([smortex](https://github.com/smortex))

**Merged pull requests:**

- gemspec: fix typo in Apache-2.0 license [\#180](https://github.com/voxpupuli/beaker-puppet/pull/180) ([bastelfreak](https://github.com/bastelfreak))
- Add Ruby 3.1 to CI [\#179](https://github.com/voxpupuli/beaker-puppet/pull/179) ([bastelfreak](https://github.com/bastelfreak))
- Depend on Ruby 2.4 or newer in gemspec [\#178](https://github.com/voxpupuli/beaker-puppet/pull/178) ([bastelfreak](https://github.com/bastelfreak))

## [1.23.0](https://github.com/voxpupuli/beaker-puppet/tree/1.23.0) (2022-02-23)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.22.2...1.23.0)

**Implemented enhancements:**

- \(maint\) Follow redirects when curling MSI [\#176](https://github.com/voxpupuli/beaker-puppet/pull/176) ([joshcooper](https://github.com/joshcooper))
- Update agent download from URL logic to handle redirects [\#173](https://github.com/voxpupuli/beaker-puppet/pull/173) ([cthorn42](https://github.com/cthorn42))

**Merged pull requests:**

- Update specs to fix ruby 3 spec failures [\#174](https://github.com/voxpupuli/beaker-puppet/pull/174) ([cthorn42](https://github.com/cthorn42))

## [1.22.2](https://github.com/voxpupuli/beaker-puppet/tree/1.22.2) (2021-12-31)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.22.1...1.22.2)

**Merged pull requests:**

- Fix install\_puppet\_on on el8 [\#170](https://github.com/voxpupuli/beaker-puppet/pull/170) ([gcampbell12](https://github.com/gcampbell12))

## [1.22.1](https://github.com/voxpupuli/beaker-puppet/tree/1.22.1) (2021-08-19)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.22.0...1.22.1)

**Merged pull requests:**

- Revert "Use the built-in Resolv::IPv4::Regex" [\#168](https://github.com/voxpupuli/beaker-puppet/pull/168) ([kenyon](https://github.com/kenyon))

## [1.22.0](https://github.com/voxpupuli/beaker-puppet/tree/1.22.0) (2021-08-17)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.21.0...1.22.0)

**Implemented enhancements:**

- Create better puppet apply tmpfiles [\#161](https://github.com/voxpupuli/beaker-puppet/pull/161) ([trevor-vaughan](https://github.com/trevor-vaughan))
- Drop stringify-hash dependency [\#158](https://github.com/voxpupuli/beaker-puppet/pull/158) ([ekohl](https://github.com/ekohl))

**Merged pull requests:**

- Remove mentions of Beaker 3 [\#165](https://github.com/voxpupuli/beaker-puppet/pull/165) ([ekohl](https://github.com/ekohl))
- Use the built-in Resolv::IPv4::Regex [\#164](https://github.com/voxpupuli/beaker-puppet/pull/164) ([ekohl](https://github.com/ekohl))
- Implement codecov; update README.md [\#162](https://github.com/voxpupuli/beaker-puppet/pull/162) ([bastelfreak](https://github.com/bastelfreak))
- Add both GPG keys when installing repos on SLES [\#157](https://github.com/voxpupuli/beaker-puppet/pull/157) ([GabrielNagy](https://github.com/GabrielNagy))

## [1.21.0](https://github.com/voxpupuli/beaker-puppet/tree/1.21.0) (2020-12-21)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.20.0...1.21.0)

**Fixed bugs:**

- Fix Arch Linux support [\#154](https://github.com/voxpupuli/beaker-puppet/pull/154) ([bastelfreak](https://github.com/bastelfreak))

**Merged pull requests:**

- \(\#151\) Remove useless 'PATH' string from system PATH [\#152](https://github.com/voxpupuli/beaker-puppet/pull/152) ([silug](https://github.com/silug))
- \(maint\) replace use of deprecated method `get_puppet_collection` [\#149](https://github.com/voxpupuli/beaker-puppet/pull/149) ([ciprianbadescu](https://github.com/ciprianbadescu))
- \(maint\) Make latest the latest stable instead of nightly [\#147](https://github.com/voxpupuli/beaker-puppet/pull/147) ([GabrielNagy](https://github.com/GabrielNagy))
- \(maint\) Remove deprecated gem install flags [\#146](https://github.com/voxpupuli/beaker-puppet/pull/146) ([gimmyxd](https://github.com/gimmyxd))
- \(maint\) redhat-8-arm64 builds access check [\#145](https://github.com/voxpupuli/beaker-puppet/pull/145) ([ciprianbadescu](https://github.com/ciprianbadescu))

## [1.20.0](https://github.com/voxpupuli/beaker-puppet/tree/1.20.0) (2020-09-10)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.19.2...1.20.0)

**Merged pull requests:**

- \(maint\) Remove puppet teams from CODEOWNERS file [\#143](https://github.com/voxpupuli/beaker-puppet/pull/143) ([lucywyman](https://github.com/lucywyman))
- Add .travis.yml [\#142](https://github.com/voxpupuli/beaker-puppet/pull/142) ([genebean](https://github.com/genebean))
- Add Dependabot to keep thins up to date [\#139](https://github.com/voxpupuli/beaker-puppet/pull/139) ([genebean](https://github.com/genebean))
- \(maint\) Update Windows test version.txt path [\#138](https://github.com/voxpupuli/beaker-puppet/pull/138) ([mihaibuzgau](https://github.com/mihaibuzgau))

## [1.19.2](https://github.com/voxpupuli/beaker-puppet/tree/1.19.2) (2020-05-21)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.19.1...1.19.2)

**Merged pull requests:**

- \(BKR-1654\) ruby\_command should work on windows localhost [\#137](https://github.com/voxpupuli/beaker-puppet/pull/137) ([Filipovici-Andrei](https://github.com/Filipovici-Andrei))

## [1.19.1](https://github.com/voxpupuli/beaker-puppet/tree/1.19.1) (2020-05-07)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.19.0...1.19.1)

**Merged pull requests:**

- \(BKR-1641\) Update Agent version defaults [\#134](https://github.com/voxpupuli/beaker-puppet/pull/134) ([sebastian-miclea](https://github.com/sebastian-miclea))

## [1.19.0](https://github.com/voxpupuli/beaker-puppet/tree/1.19.0) (2020-05-06)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.15...1.19.0)

**Merged pull requests:**

- Bump puppet and rake version [\#136](https://github.com/voxpupuli/beaker-puppet/pull/136) ([highb](https://github.com/highb))
- \(maint\) Add extra escape chars in msi-log [\#135](https://github.com/voxpupuli/beaker-puppet/pull/135) ([donoghuc](https://github.com/donoghuc))

## [1.18.15](https://github.com/voxpupuli/beaker-puppet/tree/1.18.15) (2020-03-31)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.14...1.18.15)

**Merged pull requests:**

- \(maint\) Enable Windows hosts to use the package\_proxy [\#133](https://github.com/voxpupuli/beaker-puppet/pull/133) ([markcassidy](https://github.com/markcassidy))

## [1.18.14](https://github.com/voxpupuli/beaker-puppet/tree/1.18.14) (2020-02-20)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.13...1.18.14)

**Merged pull requests:**

- Update to remove issues with type/more commands [\#131](https://github.com/voxpupuli/beaker-puppet/pull/131) ([trevor-vaughan](https://github.com/trevor-vaughan))

## [1.18.13](https://github.com/voxpupuli/beaker-puppet/tree/1.18.13) (2020-02-07)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.12...1.18.13)

**Merged pull requests:**

- Revert "Merge pull request \#129 from trevor-vaughan/windows\_paths" [\#130](https://github.com/voxpupuli/beaker-puppet/pull/130) ([gimmyxd](https://github.com/gimmyxd))

## [1.18.12](https://github.com/voxpupuli/beaker-puppet/tree/1.18.12) (2020-02-06)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.11...1.18.12)

**Merged pull requests:**

- Fix Windows Support [\#129](https://github.com/voxpupuli/beaker-puppet/pull/129) ([trevor-vaughan](https://github.com/trevor-vaughan))
- Provide a useful message if possible ISP hijacking [\#128](https://github.com/voxpupuli/beaker-puppet/pull/128) ([trevor-vaughan](https://github.com/trevor-vaughan))

## [1.18.11](https://github.com/voxpupuli/beaker-puppet/tree/1.18.11) (2019-12-10)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.10...1.18.11)

**Merged pull requests:**

- \(maint\) Allow custom hypervisor settings [\#127](https://github.com/voxpupuli/beaker-puppet/pull/127) ([melissa](https://github.com/melissa))

## [1.18.10](https://github.com/voxpupuli/beaker-puppet/tree/1.18.10) (2019-11-26)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.9...1.18.10)

**Merged pull requests:**

- \(RE-12690\) Be more explicit about when to gsub [\#126](https://github.com/voxpupuli/beaker-puppet/pull/126) ([mwaggett](https://github.com/mwaggett))

## [1.18.9](https://github.com/voxpupuli/beaker-puppet/tree/1.18.9) (2019-11-25)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.8...1.18.9)

**Merged pull requests:**

- \(RE-12690\) Add debug output to `install_repo_configs_from_url` [\#125](https://github.com/voxpupuli/beaker-puppet/pull/125) ([mwaggett](https://github.com/mwaggett))

## [1.18.8](https://github.com/voxpupuli/beaker-puppet/tree/1.18.8) (2019-09-25)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.7...1.18.8)

**Merged pull requests:**

- \(maint\) removed unused gem markdown [\#124](https://github.com/voxpupuli/beaker-puppet/pull/124) ([ciprianbadescu](https://github.com/ciprianbadescu))
- \(maint\) fix ssl cleanup [\#123](https://github.com/voxpupuli/beaker-puppet/pull/123) ([ciprianbadescu](https://github.com/ciprianbadescu))
- \(maint\) add CODEOWNERS [\#120](https://github.com/voxpupuli/beaker-puppet/pull/120) ([mihaibuzgau](https://github.com/mihaibuzgau))

## [1.18.7](https://github.com/voxpupuli/beaker-puppet/tree/1.18.7) (2019-07-18)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.6...1.18.7)

**Merged pull requests:**

- \(maint\) Using skip\_test in a step was not doing what I expected [\#119](https://github.com/voxpupuli/beaker-puppet/pull/119) ([underscorgan](https://github.com/underscorgan))

## [1.18.6](https://github.com/voxpupuli/beaker-puppet/tree/1.18.6) (2019-07-15)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.5...1.18.6)

**Merged pull requests:**

- \(maint\) Updates for rerunning tests on existing containers [\#117](https://github.com/voxpupuli/beaker-puppet/pull/117) ([underscorgan](https://github.com/underscorgan))

## [1.18.5](https://github.com/voxpupuli/beaker-puppet/tree/1.18.5) (2019-06-27)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.4...1.18.5)

**Merged pull requests:**

- \(BKR-1600\) Default puppet settings to `main` section [\#118](https://github.com/voxpupuli/beaker-puppet/pull/118) ([joshcooper](https://github.com/joshcooper))

## [1.18.4](https://github.com/voxpupuli/beaker-puppet/tree/1.18.4) (2019-06-19)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.3...1.18.4)

**Merged pull requests:**

- \(BKR-1598\) Set server hostname [\#116](https://github.com/voxpupuli/beaker-puppet/pull/116) ([joshcooper](https://github.com/joshcooper))

## [1.18.3](https://github.com/voxpupuli/beaker-puppet/tree/1.18.3) (2019-05-24)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.2...1.18.3)

**Merged pull requests:**

- \(maint\) Mark dev repos as trusted [\#115](https://github.com/voxpupuli/beaker-puppet/pull/115) ([pcarlisle](https://github.com/pcarlisle))

## [1.18.2](https://github.com/voxpupuli/beaker-puppet/tree/1.18.2) (2019-05-20)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.1...1.18.2)

**Merged pull requests:**

- \(BKR-1591\) install puppet from devbuilds on amazon [\#114](https://github.com/voxpupuli/beaker-puppet/pull/114) ([gimmyxd](https://github.com/gimmyxd))

## [1.18.1](https://github.com/voxpupuli/beaker-puppet/tree/1.18.1) (2019-05-16)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.18.0...1.18.1)

**Merged pull requests:**

- \(BKR-1587\) Install non-latest builds on all hosts [\#112](https://github.com/voxpupuli/beaker-puppet/pull/112) ([joshcooper](https://github.com/joshcooper))

## [1.18.0](https://github.com/voxpupuli/beaker-puppet/tree/1.18.0) (2019-05-15)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.17.0...1.18.0)

**Merged pull requests:**

- \(BKR-1590\) Support new yum and apt release locations [\#113](https://github.com/voxpupuli/beaker-puppet/pull/113) ([treydock](https://github.com/treydock))
- \(maint\) Restructure release repo url [\#110](https://github.com/voxpupuli/beaker-puppet/pull/110) ([melissa](https://github.com/melissa))

## [1.17.0](https://github.com/voxpupuli/beaker-puppet/tree/1.17.0) (2019-04-15)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.16.0...1.17.0)

**Merged pull requests:**

- \(maint\) Bump version of puppet-agent to test against to 6.0.0 [\#109](https://github.com/voxpupuli/beaker-puppet/pull/109) ([melissa](https://github.com/melissa))
- \(maint\) Remove assumption that we have runtime on docker [\#108](https://github.com/voxpupuli/beaker-puppet/pull/108) ([melissa](https://github.com/melissa))
- \(maint\) Added debian 10 or higher to allow insecure repo [\#107](https://github.com/voxpupuli/beaker-puppet/pull/107) ([loopinu](https://github.com/loopinu))
- \(MAINT\) Fix test:acceptance:pkg [\#106](https://github.com/voxpupuli/beaker-puppet/pull/106) ([smcelmurry](https://github.com/smcelmurry))
- \(maint\) Exclude tmp directory on module installation [\#101](https://github.com/voxpupuli/beaker-puppet/pull/101) ([glennsarti](https://github.com/glennsarti))
- \(maint\) Enable acceptance testing with puppet-agent installed from ni… [\#98](https://github.com/voxpupuli/beaker-puppet/pull/98) ([melissa](https://github.com/melissa))

## [1.16.0](https://github.com/voxpupuli/beaker-puppet/tree/1.16.0) (2019-01-29)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.15.1...1.16.0)

**Merged pull requests:**

- \(maint\) Add puppetserver package to puppet\_collection\_for [\#104](https://github.com/voxpupuli/beaker-puppet/pull/104) ([ekinanp](https://github.com/ekinanp))
- \(maint\) `agent` should be `host` [\#103](https://github.com/voxpupuli/beaker-puppet/pull/103) ([melissa](https://github.com/melissa))

## [1.15.1](https://github.com/voxpupuli/beaker-puppet/tree/1.15.1) (2019-01-28)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.15.0...1.15.1)

**Merged pull requests:**

- \(maint\) Avoid mutating frozen string [\#102](https://github.com/voxpupuli/beaker-puppet/pull/102) ([donoghuc](https://github.com/donoghuc))

## [1.15.0](https://github.com/voxpupuli/beaker-puppet/tree/1.15.0) (2019-01-25)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.14.0...1.15.0)

**Merged pull requests:**

- \(maint\) Centralize puppet\_collection\_for logic [\#100](https://github.com/voxpupuli/beaker-puppet/pull/100) ([ekinanp](https://github.com/ekinanp))
- \(maint\) return nil explicitly for agent/server version helpers [\#99](https://github.com/voxpupuli/beaker-puppet/pull/99) ([caseywilliams](https://github.com/caseywilliams))
- A few small puppet helper fixes [\#97](https://github.com/voxpupuli/beaker-puppet/pull/97) ([caseywilliams](https://github.com/caseywilliams))
- \(maint\) Fix incorrect constant reference, update a spec test description [\#96](https://github.com/voxpupuli/beaker-puppet/pull/96) ([caseywilliams](https://github.com/caseywilliams))
- \(BKR-1560\) Add install\_puppetserver\_on helper [\#95](https://github.com/voxpupuli/beaker-puppet/pull/95) ([caseywilliams](https://github.com/caseywilliams))
- \(BKR-1560\) Allow for installing puppet-agent from dev builds [\#93](https://github.com/voxpupuli/beaker-puppet/pull/93) ([caseywilliams](https://github.com/caseywilliams))
- \(maint\) Fix empty argument case in collection methods [\#92](https://github.com/voxpupuli/beaker-puppet/pull/92) ([caseywilliams](https://github.com/caseywilliams))
- \(maint\) Simplify missing SHA.yaml error message [\#91](https://github.com/voxpupuli/beaker-puppet/pull/91) ([caseywilliams](https://github.com/caseywilliams))
- \(BKR-1560\) Updates to support puppet\_agent module testing [\#89](https://github.com/voxpupuli/beaker-puppet/pull/89) ([caseywilliams](https://github.com/caseywilliams))

## [1.14.0](https://github.com/voxpupuli/beaker-puppet/tree/1.14.0) (2018-12-17)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.13.0...1.14.0)

**Merged pull requests:**

- Autodetect the target module dir in copy\_module\_to [\#83](https://github.com/voxpupuli/beaker-puppet/pull/83) ([ekohl](https://github.com/ekohl))

## [1.13.0](https://github.com/voxpupuli/beaker-puppet/tree/1.13.0) (2018-12-13)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.12.0...1.13.0)

**Implemented enhancements:**

- \(BKR-1523\) Add only-fails capability to beaker [\#76](https://github.com/voxpupuli/beaker-puppet/pull/76) ([speedofdark](https://github.com/speedofdark))

**Merged pull requests:**

- \(BKR-1558\) make sure we destroy hosts for ci:test:\* task execution [\#88](https://github.com/voxpupuli/beaker-puppet/pull/88) ([speedofdark](https://github.com/speedofdark))
- \(MAINT\) Use puppet.com URLs instead of puppetlabs.com [\#78](https://github.com/voxpupuli/beaker-puppet/pull/78) ([raphink](https://github.com/raphink))

## [1.12.0](https://github.com/voxpupuli/beaker-puppet/tree/1.12.0) (2018-11-30)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.11.0...1.12.0)

**Merged pull requests:**

- \(PA-2336\) Manually import GPG keys for SLES versions \>= 11 [\#87](https://github.com/voxpupuli/beaker-puppet/pull/87) ([ScottGarman](https://github.com/ScottGarman))

## [1.11.0](https://github.com/voxpupuli/beaker-puppet/tree/1.11.0) (2018-11-28)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.10.0...1.11.0)

**Merged pull requests:**

- Revert "\(maint\) Add AIX yum bootstrap to setup scripts" [\#86](https://github.com/voxpupuli/beaker-puppet/pull/86) ([geoffnichols](https://github.com/geoffnichols))

## [1.10.0](https://github.com/voxpupuli/beaker-puppet/tree/1.10.0) (2018-11-27)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.9.0...1.10.0)

**Merged pull requests:**

- \(maint\) Set `server` in puppet.conf in ValidateSignCert [\#85](https://github.com/voxpupuli/beaker-puppet/pull/85) ([caseywilliams](https://github.com/caseywilliams))

## [1.9.0](https://github.com/voxpupuli/beaker-puppet/tree/1.9.0) (2018-11-26)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.8.0...1.9.0)

**Merged pull requests:**

- \(maint\) Add AIX yum bootstrap to setup scripts [\#84](https://github.com/voxpupuli/beaker-puppet/pull/84) ([geoffnichols](https://github.com/geoffnichols))
- \(maint\) If iptables doesn't exist, don't fail [\#82](https://github.com/voxpupuli/beaker-puppet/pull/82) ([melissa](https://github.com/melissa))
- \(maint\) Add docker specifics to git testing [\#81](https://github.com/voxpupuli/beaker-puppet/pull/81) ([melissa](https://github.com/melissa))

## [1.8.0](https://github.com/voxpupuli/beaker-puppet/tree/1.8.0) (2018-11-05)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.7.0...1.8.0)

**Implemented enhancements:**

- \(PUP-8305\) Consume the puppet-runtime archive [\#75](https://github.com/voxpupuli/beaker-puppet/pull/75) ([melissa](https://github.com/melissa))

**Merged pull requests:**

- \(maint\) Example variables in comments shouldn't be valid syntax so ru… [\#80](https://github.com/voxpupuli/beaker-puppet/pull/80) ([melissa](https://github.com/melissa))

## [1.7.0](https://github.com/voxpupuli/beaker-puppet/tree/1.7.0) (2018-10-25)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.6.0...1.7.0)

**Merged pull requests:**

- \(PA-2183\) Quote fact name in fact\_on helper [\#79](https://github.com/voxpupuli/beaker-puppet/pull/79) ([ekinanp](https://github.com/ekinanp))
- Revert "\(PUP-8305\) Git testing should consume the runtime package" [\#74](https://github.com/voxpupuli/beaker-puppet/pull/74) ([kevpl](https://github.com/kevpl))
- \(maint\) Validate `fact_on` `name` parameter [\#73](https://github.com/voxpupuli/beaker-puppet/pull/73) ([alexjfisher](https://github.com/alexjfisher))
- \(PUP-9136\) Ensure state is preserved between runs [\#72](https://github.com/voxpupuli/beaker-puppet/pull/72) ([melissa](https://github.com/melissa))
- \(PUP-8305\) Git testing should consume the runtime package [\#52](https://github.com/voxpupuli/beaker-puppet/pull/52) ([melissa](https://github.com/melissa))

## [1.6.0](https://github.com/voxpupuli/beaker-puppet/tree/1.6.0) (2018-09-14)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.5.0...1.6.0)

**Merged pull requests:**

- \(PE-25146\) Check for hostnames when puppetserver signing [\#70](https://github.com/voxpupuli/beaker-puppet/pull/70) ([jpartlow](https://github.com/jpartlow))

## [1.5.0](https://github.com/voxpupuli/beaker-puppet/tree/1.5.0) (2018-09-13)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.4.0...1.5.0)

**Merged pull requests:**

- \(maint\) Get stdout of calls to `puppet --version` [\#69](https://github.com/voxpupuli/beaker-puppet/pull/69) ([Magisus](https://github.com/Magisus))
- \(MAINT\) Updates to support GCE and RHEL [\#27](https://github.com/voxpupuli/beaker-puppet/pull/27) ([trevor-vaughan](https://github.com/trevor-vaughan))

## [1.4.0](https://github.com/voxpupuli/beaker-puppet/tree/1.4.0) (2018-09-13)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.3.0...1.4.0)

**Merged pull requests:**

- \(MODULES-7793\) Avoid stat name conflicts by renaming stat -\> beaker\_stat [\#68](https://github.com/voxpupuli/beaker-puppet/pull/68) ([justinstoller](https://github.com/justinstoller))
- \(maint\) Merge up 0.x [\#67](https://github.com/voxpupuli/beaker-puppet/pull/67) ([justinstoller](https://github.com/justinstoller))
- \(BKR-1528\) Use `puppetserver ca` instead of `puppet cert` [\#66](https://github.com/voxpupuli/beaker-puppet/pull/66) ([Magisus](https://github.com/Magisus))

## [1.3.0](https://github.com/voxpupuli/beaker-puppet/tree/1.3.0) (2018-09-11)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.2.0...1.3.0)

**Merged pull requests:**

- pass hiera\_config argument to puppet\_apply [\#63](https://github.com/voxpupuli/beaker-puppet/pull/63) ([lmayorga1980](https://github.com/lmayorga1980))

## [1.2.0](https://github.com/voxpupuli/beaker-puppet/tree/1.2.0) (2018-09-11)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.1.0...1.2.0)

**Merged pull requests:**

- \(BKR-1445\) Update Windows agent paths for puppet6 [\#64](https://github.com/voxpupuli/beaker-puppet/pull/64) ([caseywilliams](https://github.com/caseywilliams))
- \(BKR-1510\) make fact helpers support structured facts [\#59](https://github.com/voxpupuli/beaker-puppet/pull/59) ([sevendials](https://github.com/sevendials))
- \(MAINT\) Adding some generic host helper utility methods [\#54](https://github.com/voxpupuli/beaker-puppet/pull/54) ([jsane](https://github.com/jsane))

## [1.1.0](https://github.com/voxpupuli/beaker-puppet/tree/1.1.0) (2018-08-13)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.0.1...1.1.0)

**Merged pull requests:**

- PE-24898 Set puppet collection value associated with agent version [\#60](https://github.com/voxpupuli/beaker-puppet/pull/60) ([shaigy](https://github.com/shaigy))

## [1.0.1](https://github.com/voxpupuli/beaker-puppet/tree/1.0.1) (2018-08-10)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/1.0.0...1.0.1)

**Merged pull requests:**

- \(BKR-1509\) Beaker 4.0 Compatibility [\#62](https://github.com/voxpupuli/beaker-puppet/pull/62) ([Dakta](https://github.com/Dakta))

## [1.0.0](https://github.com/voxpupuli/beaker-puppet/tree/1.0.0) (2018-08-06)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.17.1...1.0.0)

**Merged pull requests:**

- Revert "Revert "\(BKR-496\) Move create\_tmpdir\_on from beaker"" [\#58](https://github.com/voxpupuli/beaker-puppet/pull/58) ([Dakta](https://github.com/Dakta))
- \(BKR-1500\) Dependency Cleanup [\#55](https://github.com/voxpupuli/beaker-puppet/pull/55) ([Dakta](https://github.com/Dakta))

## [0.17.1](https://github.com/voxpupuli/beaker-puppet/tree/0.17.1) (2018-07-27)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.17.0...0.17.1)

**Merged pull requests:**

- Revert "\(BKR-496\) Move create\_tmpdir\_on from beaker" [\#57](https://github.com/voxpupuli/beaker-puppet/pull/57) ([kevpl](https://github.com/kevpl))

## [0.17.0](https://github.com/voxpupuli/beaker-puppet/tree/0.17.0) (2018-07-26)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.16.0...0.17.0)

**Merged pull requests:**

- \(BKR-496\) Move create\_tmpdir\_on from beaker [\#56](https://github.com/voxpupuli/beaker-puppet/pull/56) ([Dakta](https://github.com/Dakta))

## [0.16.0](https://github.com/voxpupuli/beaker-puppet/tree/0.16.0) (2018-07-05)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.15.2...0.16.0)

**Merged pull requests:**

- \(BKR-1484\) Packaging platform overrides for puppet5 install utils [\#53](https://github.com/voxpupuli/beaker-puppet/pull/53) ([caseywilliams](https://github.com/caseywilliams))
- \(MAINT\) pin fakefs to \< 0.14.0 for ruby 2.2 [\#51](https://github.com/voxpupuli/beaker-puppet/pull/51) ([kevpl](https://github.com/kevpl))

## [0.15.2](https://github.com/voxpupuli/beaker-puppet/tree/0.15.2) (2018-05-07)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.15.1...0.15.2)

**Merged pull requests:**

- BKR-1465 - install\_puppet\_on -"opts" defaults "options" [\#50](https://github.com/voxpupuli/beaker-puppet/pull/50) ([gunzl1ng3r](https://github.com/gunzl1ng3r))
- \(RE-10734\) Use nightlies.puppet.com for nightly collections [\#47](https://github.com/voxpupuli/beaker-puppet/pull/47) ([hunner](https://github.com/hunner))

## [0.15.1](https://github.com/voxpupuli/beaker-puppet/tree/0.15.1) (2018-05-04)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.15.0...0.15.1)

**Merged pull requests:**

- \(BKR-1462\) Another Ubuntu 18.04 check to allow insecure repo use [\#49](https://github.com/voxpupuli/beaker-puppet/pull/49) ([ScottGarman](https://github.com/ScottGarman))

## [0.15.0](https://github.com/voxpupuli/beaker-puppet/tree/0.15.0) (2018-05-03)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.14.0...0.15.0)

**Merged pull requests:**

- \(BKR-1462\) Allow unsigned apt repositories for Ubuntu 18.04 hosts [\#46](https://github.com/voxpupuli/beaker-puppet/pull/46) ([ScottGarman](https://github.com/ScottGarman))

## [0.14.0](https://github.com/voxpupuli/beaker-puppet/tree/0.14.0) (2018-05-01)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.13.6...0.14.0)

**Merged pull requests:**

- \(CPR-570\) Import the gpg signing key on sles 11 [\#45](https://github.com/voxpupuli/beaker-puppet/pull/45) ([melissa](https://github.com/melissa))

## [0.13.6](https://github.com/voxpupuli/beaker-puppet/tree/0.13.6) (2018-04-26)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.13.5...0.13.6)

**Merged pull requests:**

- Use puppet-agent specific helper when installing the MSI [\#43](https://github.com/voxpupuli/beaker-puppet/pull/43) ([joshcooper](https://github.com/joshcooper))

## [0.13.5](https://github.com/voxpupuli/beaker-puppet/tree/0.13.5) (2018-04-25)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.13.4...0.13.5)

**Merged pull requests:**

- \(maint\) Fix failing puppet5\_spec test due to changes in pr \#39 [\#42](https://github.com/voxpupuli/beaker-puppet/pull/42) ([mchllweeks](https://github.com/mchllweeks))
- Use --module-repository for a custom forge [\#40](https://github.com/voxpupuli/beaker-puppet/pull/40) ([ekohl](https://github.com/ekohl))

## [0.13.4](https://github.com/voxpupuli/beaker-puppet/tree/0.13.4) (2018-04-23)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.13.3...0.13.4)

**Merged pull requests:**

- \(BKR-1438\) Do not use `puppet master` [\#41](https://github.com/voxpupuli/beaker-puppet/pull/41) ([pcarlisle](https://github.com/pcarlisle))

## [0.13.3](https://github.com/voxpupuli/beaker-puppet/tree/0.13.3) (2018-04-16)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.13.2...0.13.3)

**Merged pull requests:**

- Maint/master/small changes [\#39](https://github.com/voxpupuli/beaker-puppet/pull/39) ([melissa](https://github.com/melissa))
- \(maint\) Bring additional changes from puppet-agent acceptance [\#36](https://github.com/voxpupuli/beaker-puppet/pull/36) ([melissa](https://github.com/melissa))

## [0.13.2](https://github.com/voxpupuli/beaker-puppet/tree/0.13.2) (2018-04-11)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.13.1...0.13.2)

**Merged pull requests:**

- \(BKR-1453\) Ensure no agent lock after stopping puppet service [\#38](https://github.com/voxpupuli/beaker-puppet/pull/38) ([cthorn42](https://github.com/cthorn42))
- \(maint\) Add information about additional ENV vars [\#37](https://github.com/voxpupuli/beaker-puppet/pull/37) ([melissa](https://github.com/melissa))

## [0.13.1](https://github.com/voxpupuli/beaker-puppet/tree/0.13.1) (2018-04-09)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.13.0...0.13.1)

**Merged pull requests:**

- \(BKR-1443\) Ensure we do not destroy hosts if specified [\#35](https://github.com/voxpupuli/beaker-puppet/pull/35) ([melissa](https://github.com/melissa))

## [0.13.0](https://github.com/voxpupuli/beaker-puppet/tree/0.13.0) (2018-03-30)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.12.0...0.13.0)

**Merged pull requests:**

- Maint/master/skip master tests [\#34](https://github.com/voxpupuli/beaker-puppet/pull/34) ([melissa](https://github.com/melissa))

## [0.12.0](https://github.com/voxpupuli/beaker-puppet/tree/0.12.0) (2018-03-26)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.11.1...0.12.0)

**Merged pull requests:**

- \(maint\) Add release information to the readme [\#33](https://github.com/voxpupuli/beaker-puppet/pull/33) ([melissa](https://github.com/melissa))
- \(PA-1915\) Test components against nightly puppetserver [\#30](https://github.com/voxpupuli/beaker-puppet/pull/30) ([melissa](https://github.com/melissa))

## [0.11.1](https://github.com/voxpupuli/beaker-puppet/tree/0.11.1) (2018-03-26)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.11.0...0.11.1)

**Merged pull requests:**

- \(maint\) Pre suite paths must be relative [\#32](https://github.com/voxpupuli/beaker-puppet/pull/32) ([melissa](https://github.com/melissa))
- \(maint\) Remove references to 'ci:test:quick' [\#29](https://github.com/voxpupuli/beaker-puppet/pull/29) ([melissa](https://github.com/melissa))

## [0.11.0](https://github.com/voxpupuli/beaker-puppet/tree/0.11.0) (2018-03-20)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.10.0...0.11.0)

**Merged pull requests:**

- \(BKR-1342\) Import ci rake tasks and install utils [\#26](https://github.com/voxpupuli/beaker-puppet/pull/26) ([melissa](https://github.com/melissa))

## [0.10.0](https://github.com/voxpupuli/beaker-puppet/tree/0.10.0) (2018-01-11)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.9.0...0.10.0)

**Merged pull requests:**

- \(BKR-1385\) Install rpm packages on aix [\#25](https://github.com/voxpupuli/beaker-puppet/pull/25) ([melissa](https://github.com/melissa))
- \(maint\) Refactor puppet5 install logic [\#24](https://github.com/voxpupuli/beaker-puppet/pull/24) ([joshcooper](https://github.com/joshcooper))
- \(BKR-1343\) Install as an MSI on Windows [\#23](https://github.com/voxpupuli/beaker-puppet/pull/23) ([joshcooper](https://github.com/joshcooper))
- \(maint\) Remove unnecessary logger information [\#22](https://github.com/voxpupuli/beaker-puppet/pull/22) ([melissa](https://github.com/melissa))

## [0.9.0](https://github.com/voxpupuli/beaker-puppet/tree/0.9.0) (2018-01-04)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.8.0...0.9.0)

**Merged pull requests:**

- \(maint\) Add beaker-abs to Gemfile [\#21](https://github.com/voxpupuli/beaker-puppet/pull/21) ([smcelmurry](https://github.com/smcelmurry))

## [0.8.0](https://github.com/voxpupuli/beaker-puppet/tree/0.8.0) (2017-10-13)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.7.0...0.8.0)

**Merged pull requests:**

- \(MAINT\) add contributing guide to README [\#19](https://github.com/voxpupuli/beaker-puppet/pull/19) ([kevpl](https://github.com/kevpl))
- \(maint\) Update beaker to support pupppet5 style installation [\#18](https://github.com/voxpupuli/beaker-puppet/pull/18) ([melissa](https://github.com/melissa))

## [0.7.0](https://github.com/voxpupuli/beaker-puppet/tree/0.7.0) (2017-09-15)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.6.0...0.7.0)

**Merged pull requests:**

- \(maint\) Allow user to pass in host target [\#16](https://github.com/voxpupuli/beaker-puppet/pull/16) ([melissa](https://github.com/melissa))

## [0.6.0](https://github.com/voxpupuli/beaker-puppet/tree/0.6.0) (2017-08-21)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.5.0...0.6.0)

**Merged pull requests:**

- \(BKR-1118\) add puppet5 install method [\#6](https://github.com/voxpupuli/beaker-puppet/pull/6) ([kevpl](https://github.com/kevpl))

## [0.5.0](https://github.com/voxpupuli/beaker-puppet/tree/0.5.0) (2017-08-18)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.4.0...0.5.0)

**Merged pull requests:**

- \(BKR-1185\) Use Oga instead of Nokogiri [\#15](https://github.com/voxpupuli/beaker-puppet/pull/15) ([rishijavia](https://github.com/rishijavia))
- \(MAINT\) fix windows spec failures [\#14](https://github.com/voxpupuli/beaker-puppet/pull/14) ([tvpartytonight](https://github.com/tvpartytonight))
- \(MAINT\) remove `dev_builds_repos` mentions [\#8](https://github.com/voxpupuli/beaker-puppet/pull/8) ([kevpl](https://github.com/kevpl))

## [0.4.0](https://github.com/voxpupuli/beaker-puppet/tree/0.4.0) (2017-07-26)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.3.0...0.4.0)

**Merged pull requests:**

- \(BKR-1164\) Add ubuntu to the platform list in remove\_puppet\_on [\#11](https://github.com/voxpupuli/beaker-puppet/pull/11) ([ScottGarman](https://github.com/ScottGarman))

## [0.3.0](https://github.com/voxpupuli/beaker-puppet/tree/0.3.0) (2017-07-17)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.2.0...0.3.0)

**Merged pull requests:**

- \(BKR-1159\) Reset opts in install\_puppet\_agent\_dev\_repo\_on [\#10](https://github.com/voxpupuli/beaker-puppet/pull/10) ([johnduarte](https://github.com/johnduarte))

## [0.2.0](https://github.com/voxpupuli/beaker-puppet/tree/0.2.0) (2017-06-28)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/0.1.0...0.2.0)

**Merged pull requests:**

- \(BKR-1147\) Fail to pkg install on ec2 for dev-repo [\#7](https://github.com/voxpupuli/beaker-puppet/pull/7) ([johnduarte](https://github.com/johnduarte))
- \(BKR-895\) add missing install\_utils tests [\#5](https://github.com/voxpupuli/beaker-puppet/pull/5) ([kevpl](https://github.com/kevpl))

## [0.1.0](https://github.com/voxpupuli/beaker-puppet/tree/0.1.0) (2017-06-16)

[Full Changelog](https://github.com/voxpupuli/beaker-puppet/compare/3878c13311bf5ddcda043f5c23cb1354614a997a...0.1.0)

**Merged pull requests:**

- \(MAINT\) fix coverage env-var name [\#4](https://github.com/voxpupuli/beaker-puppet/pull/4) ([kevpl](https://github.com/kevpl))
- \(MAINT\) improve README description [\#3](https://github.com/voxpupuli/beaker-puppet/pull/3) ([kevpl](https://github.com/kevpl))
- \(MAINT\) fix DSL inclusion [\#2](https://github.com/voxpupuli/beaker-puppet/pull/2) ([kevpl](https://github.com/kevpl))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
