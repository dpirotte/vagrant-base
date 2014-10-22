class base {
  $user = "vagrant"

  $installed_packages = [
    "autojump",
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

  class { "ohmyzsh": require => Package["zsh"] }
  ohmyzsh::install { $user: }
  ohmyzsh::plugins { $user: plugins => "autojump git lein rbenv" }

  user { $user:
    shell => "/usr/bin/zsh",
    require => [
      Package["zsh"],
      Class["ohmyzsh"],
    ],
  }
}

class oracle_java {
  include apt
  exec { "accept-oracle-java-license": 
    command => 'echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections',
    unless => 'sudo /usr/bin/debconf-get-selections | grep shared/accepted-oracle-license-v1-1',
    path => ["/bin","/usr/bin"],
  }
  apt::ppa { "ppa:webupd8team/java": }
  package { "oracle-java8-installer":
    require => [
      Exec["accept-oracle-java-license"],
      Apt::Ppa["ppa:webupd8team/java"],
    ],
  }
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

class dotfiles {
  $dotfiles_root = "/home/vagrant/dotfiles"

  package { "ruby-dev": ensure => installed }

  file { $dotfiles_root:
    ensure => "directory",
    owner => "vagrant",
    group => "vagrant",
    mode => "0755"
  }

  vcsrepo { "${dotfiles_root}/vim_dotfiles":
    ensure => "present",
    provider => "git",
    owner => "vagrant",
    group => "vagrant",
    source => "https://github.com/braintreeps/vim_dotfiles.git",
    require => File[$dotfiles_root],
  }

  exec { "link-vim-dotfiles":
    cwd => "${dotfiles_root}/vim_dotfiles",
    environment => "HOME=/home/vagrant",
    command => "/usr/bin/rake1.9.1 activate",
    creates => "/home/vagrant/.vimrc",
    require => Vcsrepo["${dotfiles_root}/vim_dotfiles"],
  }
  
  exec { "build-command-t":
    cwd => "${dotfiles_root}/vim_dotfiles/vim/bundle/command-t",
    environment => "HOME=/home/vagrant",
    command => "/usr/bin/rake1.9.1 make",
    creates => "${dotfiles_root}/vim_dotfiles/vim/bundle/command-t/ruby/command-t/ext.so",
    require => [
      Package["ruby-dev"],
      Vcsrepo["${dotfiles_root}/vim_dotfiles"],
    ],
  }
}

node "vagrant" {
  include base
  include dotfiles
  include leiningen
  include oracle_java
}
