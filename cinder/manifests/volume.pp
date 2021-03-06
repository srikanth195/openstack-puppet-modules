# == Class: cinder::volume
#
# === Parameters
#
# [*package_ensure*]
#   (Optional) The state of the package.
#   Defaults to 'present'.
#
# [*enabled*]
#   (Optional) The state of the service
#   Defaults to 'true'.
#
# [*manage_service*]
#   (Optional) Whether to start/stop the service.
#   Defaults to 'true'.
#
# [*volume_clear*]
#   (Optional) Method used to wipe old volumes.
#   Defaults to $::os_service_default.
#
# [*volume_clear_size*]
#   (Optional) Size in MiB to wipe at start of old volumes.
#   Set to '0' means all.
#   Defaults to $::os_service_default.
#
# [*volume_clear_ionice*]
#   (Optional) The flag to pass to ionice to alter the i/o priority
#   of the process used to zero a volume after deletion,
#   for example "-c3" for idle only priority.
#   Defaults to $::os_service_default.
#
class cinder::volume (
  $package_ensure      = 'present',
  $enabled             = true,
  $manage_service      = true,
  $volume_clear        = $::os_service_default,
  $volume_clear_size   = $::os_service_default,
  $volume_clear_ionice = $::os_service_default,
) {

  include ::cinder::params

  Cinder_config<||> ~> Service['cinder-volume']
  Cinder_api_paste_ini<||> ~> Service['cinder-volume']
  Exec<| title == 'cinder-manage db_sync' |> ~> Service['cinder-volume']

  if $::cinder::params::volume_package {
    Package['cinder']        -> Package['cinder-volume']
    Package['cinder-volume'] -> Service['cinder-volume']
    package { 'cinder-volume':
      ensure => $package_ensure,
      name   => $::cinder::params::volume_package,
      tag    => ['openstack', 'cinder-package'],
    }
  }

  if $manage_service {
    if $enabled {
      $ensure = 'running'
    } else {
      $ensure = 'stopped'
    }
  }

  service { 'cinder-volume':
    ensure    => $ensure,
    name      => $::cinder::params::volume_service,
    enable    => $enabled,
    hasstatus => true,
    require   => Package['cinder'],
    tag       => 'cinder-service',
  }

  cinder_config {
    'DEFAULT/volume_clear':        value => $volume_clear;
    'DEFAULT/volume_clear_size':   value => $volume_clear_size;
    'DEFAULT/volume_clear_ionice': value => $volume_clear_ionice;
  }
}
