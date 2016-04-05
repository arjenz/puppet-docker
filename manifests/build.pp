# @define tp_docker::build
#
define tp_docker::build (

  String[1]               $ensure              = 'present',

  Variant[Undef,String]   $template            = 'tp_docker/Dockerfile.erb',
  String[1]               $workdir             = '/var/tmp',

  String[1]               $username            = 'example42',

  String[1]               $os                  = downcase($::operatingsystem),
  String[1]               $osversion           = $::operatingsystemmajrelease,

  Variant[Undef,String]   $maintainer          = undef,
  Variant[Undef,String]   $from                = undef,

  Variant[Undef,String]   $repository          = $title,
  Variant[Undef,String]   $repository_tag      = 'latest',

  Variant[Undef,Array]    $exec_environment    = undef,

  String                  $build_options       = '',
  Pattern[/command|supervisor/] $command_mode  = 'supervisor',

  Boolean                 $mount_data_dir      = true,
  Boolean                 $mount_log_dir       = true,

  Hash                    $settings_hash       = {},

  String[1]               $data_module         = 'tinydata',

  ) {

  # Settings evaluation
  $app = $title
  $tp_settings = tp_lookup($app,'settings',$data_module,'merge')
  $settings_supervisor = tp_lookup('supervisor','settings',$data_module,'merge')
  $settings = $tp_settings + $settings_hash

  $real_from = $from ? {
    undef   => "${os}:${osversion}",
    default => $from,
  }
  $basedir_path = "${workdir}/${username}/${os}/${osversion}/${app}"

  Exec {
    path    => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin',
    timeout => 3000,
  }

  # Dockerfile creation
  exec { "mkdir -p ${basedir_path}":
    creates => $basedir_path,
  } ->
  file { "${basedir_path}/Dockerfile":
    ensure  => $ensure,
    content => template($template),
  }

  exec { "docker build ${build_options} -t ${username}/${repository}:${real_repository_tag} ${basedir_path}":
    cwd         => $basedir_path,
    subscribe   => File["${basedir_path}/Dockerfile"],
    environment => $exec_environment,
  }

}