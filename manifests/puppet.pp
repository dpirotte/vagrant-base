class base {
  $installed_packages = [
    "vim-nox",
  ]

  $purged_packages = [
    "chef",
  ]

  package { $installed_packages: ensure => "installed" }
  package { $purged_packages: ensure => "purged" }

}

class oracle_java {
  include apt
  exec { "accept-oracle-java-license": 
    command => 'echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections',
    unless => 'sudo /usr/bin/debconf-get-selections | grep shared/accepted-oracle-license-v1-1',
    path => ["/bin","/usr/bin"],
  }
  apt::ppa { "ppa:webupd8team/java": }
  package { "oracle-java8-installer": require => Exec["accept-oracle-java-license"] }
}

node "vagrant" {
  include base
  include oracle_java
}
