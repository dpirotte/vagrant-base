node "vagrant" {
  $installed_packages = [
    "vim-nox"
  ]

  $purged_packages = [
    "chef"
  ]

  package { $installed_packages: ensure => "installed" }
  package { $purged_packages: ensure => "purged" }
}
