# @define tp_docker::dockerize
#
# This define dockerizes an application.
# It can:
#   - Create a dockerfile based on tinydata (default: false)
#   - Build the relevant image (default:false)
#   - Push the image to Docker Hub (default:false)
#   - Run the image from the Docker Hub (default:true)
#
define tp_docker::dockerize (

  String[1]               $ensure              = 'present',

  Variant[Undef,String]   $template            = 'tp/dockerize/Dockerfile.erb',
  Variant[Undef,String]   $init_template       = 'tp/dockerize/init.erb',
  String[1]               $workdir             = '/var/tmp',

  String[1]               $username            = 'example42',

  String[1]               $os                  = downcase($::operatingsystem),
  String[1]               $osversion           = $::operatingsystemmajrelease,

  Variant[Undef,String]   $maintainer          = undef,
  Variant[Undef,String]   $from                = undef,

  Variant[Undef,String]   $repository          = undef,
  Variant[Undef,String]   $repository_tag      = undef,

  Boolean                 $run                 = true,
  Boolean                 $create              = false,
  Boolean                 $build               = false,
  Boolean                 $push                = false,

  Variant[Undef,Array]    $exec_environment    = undef,

  String                  $build_options       = '',
  Pattern[/command|supervisor/] $command_mode  = 'supervisor',
  Pattern[/service|commnad/]    $run_mode      = 'command',

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

  $real_repository = $repository ? {
    undef   => $app,
    default => $repository,
  }
  $real_repository_tag = $repository_tag ? {
    undef   => "${os}-${osversion}",
    default => $repository_tag,
  }
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
  if $create {
    tp_docker::build { $app:
      ensure           => $ensure,
      build_options    => $build_options,
      username         => $username,
      repository       => $real_repository,
      repository_tag   => $real_repository_tag,
      basedir_path     => $basedir_path:
      exec_environment => $exec_environment,
    }
  }

  # Image upload to Docker Hub
  if $push {
    tp_docker::push { $app:
      ensure           => $ensure,
      username         => $username,
      repository       => $real_repository,
      repository_tag   => $real_repository_tag,
      exec_environment => $exec_environment,
    }
  }

  # Image run
  if $run {
    tp_docker::run { $app:
      ensure           => $ensure,
      username         => $username,
      repository       => $real_repository,
      repository_tag   => $real_repository_tag,
      exec_environment => $exec_environment,
      run_mode         => $run_mode,
    }
  if $run {
    $service_ensure = $ensure ? {
      'absent' => 'stopped',
      false    => 'stopped',
      default  => $settings[service_ensure],
    }
    $service_enable = $ensure ? {
      'absent' => false,
      false    => false,
      default  => $settings[service_enable],
    }
    exec { "docker pull ${username}/${real_repository}:${real_repository_tag}":
      unless      => "docker images | grep ${username}/${real_repository} | grep ${real_repository_tag}",
      environment => $exec_environment,
    }
    file { "/etc/init/docker-${app}":
      ensure  => $ensure,
      content => template($init_template),
      mode    => '0755',
      notify  => Service["docker-${app}"],
    }
    service { "docker-${app}":
      ensure  => $service_ensure,
      enable  => $service_enable,
    }
  }

}
