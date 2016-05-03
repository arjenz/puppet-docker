# == Class: docker::compose
#
# Class to install Docker Compose using the recommended curl command.
# Original source: https://github.com/garethr/garethr-docker/blob/master/manifests/compose.pp
#
# === Parameters
#
# [*ensure*]
#   Whether to install or remove Docker Compose
#   Valid values are absent present
#   Defaults to present
#
# [*real_version*]
#   The real_version of Docker Compose to install.
#   Defaults to the value set in $docker::params::compose_real_version
#
class docker::compose(
  Variant[Boolean,String]  $ensure           = present,
  Hash                     $options          = { },
  Variant[Undef,String[1]] $template         = undef,
  Variant[Undef,String[1]] $version          = undef,
) {

  include docker

  $real_version = $version {
    undef   => $::docker::settings['compose_version'],
    default => $version,
  }

  if $ensure == 'present' {
    exec { "Install Docker Compose ${real_version}":
      path    => '/usr/bin/',
      cwd     => '/tmp',
      command => "curl -s -L https://github.com/docker/compose/releases/download/${real_version}/docker-compose-${::kernel}-x86_64 > /usr/local/bin/docker-compose-${real_version}",
      creates => "/usr/local/bin/docker-compose-${real_version}"
    } ->
    file { "/usr/local/bin/docker-compose-${real_version}":
      owner => 'root',
      mode  => '0755'
    } ->
    file { '/usr/local/bin/docker-compose':
      ensure => 'link',
      target => "/usr/local/bin/docker-compose-${real_version}",
    }
  } else {
    file { [
      "/usr/local/bin/docker-compose-${real_version}",
      '/usr/local/bin/docker-compose'
    ]:
      ensure => absent,
    }
  }
}
