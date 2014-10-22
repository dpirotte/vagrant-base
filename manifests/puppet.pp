class base {
  $user = "vagrant"

  $installed_packages = [
    "vim-nox",
    "zsh",
  ]

  $purged_packages = [
    "chef",
  ]

  package { $installed_packages: ensure => "installed" }
  package { $purged_packages: ensure => "purged" }

  service { "puppet":
    ensure => "stopped",
    enable => false,
  }

  rbenv::install { $user: }
  rbenv::compile { "2.1.3":
    user => $user,
    global => true,
  }

  user { $user:
    shell => "/usr/bin/zsh",
  }

  class { "ohmyzsh": require => Package["zsh"] }
  ohmyzsh::install { $user: }
  ohmyzsh::plugins { $user: plugins => "git lein rbenv" }
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

class leiningen {
  $url = "https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein"
  $bindir = "/home/vagrant/bin"

  file { $bindir:
    ensure => directory,
    owner => $user,
    group => $user,
    mode => 0755,
  }

  exec { "download-leiningen":
    cwd => $bindir,
    command => "wget ${url}",
    creates => "${bindir}/lein",
    path => "/usr/bin",
    require => File[$bindir],
  }

  file { "${bindir}/lein":
    ensure => file,
    mode => 0755,
    require => Exec["download-leiningen"]
  }
}

node "vagrant" {
  include base
  include leiningen
  include oracle_java
}
