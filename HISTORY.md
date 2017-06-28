# worker - History
## Tags
* [LATEST - 28 Jun, 2017 (63cbd942)](#LATEST)
* [0.1.0 - 16 Jun, 2017 (e9be23b0)](#0.1.0)

## Details
### <a name = "LATEST">LATEST - 28 Jun, 2017 (63cbd942)

* (GEM) update beaker-puppet version to 0.2.0 (63cbd942)

* Merge pull request #7 from johnduarte/issues/master/bkr-1147/fail-to-pkg-install-on-ec2-el (dd8d640f)


```
Merge pull request #7 from johnduarte/issues/master/bkr-1147/fail-to-pkg-install-on-ec2-el

(BKR-1147) Fail to pkg install on ec2 for dev-repo
```
* (BKR-1147) Fail to pkg install on ec2 for dev-repo (89909fa7)


```
(BKR-1147) Fail to pkg install on ec2 for dev-repo

This commit modifies the `install_puppet_agent_dev_repo_on` method
to install the puppet-agent package if the host is on ec2 and el.
This is done because the ec2 instance does not have access to the
default dev repo.
```
* Merge pull request #5 from kevpl/bkr895_installutils_tests (e54d7fd2)


```
Merge pull request #5 from kevpl/bkr895_installutils_tests

(BKR-895) add missing install_utils tests
```
* (BKR-895) add missing install_utils tests (d6f243ed)

### <a name = "0.1.0">0.1.0 - 16 Jun, 2017 (e9be23b0)

* Initial release.
