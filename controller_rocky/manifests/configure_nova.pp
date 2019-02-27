class controller_rocky::configure_nova inherits controller_rocky::params {

#
# Questa classe:
# - popola il file /etc/nova/nova.conf
# - crea il file /etc/nova/policy.json in modo che solo l'owner di una VM possa farne lo stop e delete
# 
###################  
define do_config ($conf_file, $section, $param, $value) {
             exec { "${name}":
                              command     => "/usr/bin/openstack-config --set ${conf_file} ${section} ${param} \"${value}\"",
                              require     => Package['openstack-utils'],
                              unless      => "/usr/bin/openstack-config --get ${conf_file} ${section} ${param} 2>/dev/null | /bin/grep -- \"^${value}$\" 2>&1 >/dev/null",
                  }
       }

define remove_config ($conf_file, $section, $param, $value) {
             exec { "${name}":
                              command     => "/usr/bin/openstack-config --del ${conf_file} ${section} ${param}",
                              require     => Package['openstack-utils'],
                              onlyif      => "/usr/bin/openstack-config --get ${conf_file} ${section} ${param} 2>/dev/null | /bin/grep -- \"^${value}$\" 2>&1 >/dev/null",
                   }
       }


define do_augeas_config ($conf_file, $section, $param) {
    $split = split($name, '~')
    $value = $split[-1]
    $index = $split[-2]

    augeas { "augeas/${conf_file}/${section}/${param}/${index}/${name}":
          lens    => "PythonPaste.lns",
          incl    => $conf_file,
          changes => [ "set ${section}/${param}[${index}] ${value}" ],
          onlyif  => "get ${section}/${param}[${index}] != ${value}"
        }
        }
        

define do_config_list ($conf_file, $section, $param, $values) {
    $values_size = size($values)

    # remove the entire block if the size doesn't match
    augeas { "remove_${conf_file}_${section}_${param}":
          lens    => "PythonPaste.lns",
          incl    => $conf_file,
          changes => [ "rm ${section}/${param}" ],
          onlyif  => "match ${section}/${param} size > ${values_size}"
        }
        
    $namevars = array_to_namevars($values, "${conf_file}~${section}~${param}", "~")

    # check each value
    do_augeas_config { $namevars:
            conf_file => $conf_file,
            section => $section,
            param => $param
              }
    }
              

       
# nova.conf
   do_config { 'nova_auth_strategy': conf_file => '/etc/nova/nova.conf', section => 'api', param => 'auth_strategy', value => $controller_rocky::params::auth_strategy, }

   do_config { 'nova_transport_url': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'transport_url', value => $controller_rocky::params::transport_url, }
   do_config { 'nova_my_ip': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'my_ip', value => $controller_rocky::params::vip_mgmt, }
   ### FF DEPRECATED in PIKE firewall_driver 
   #do_config { 'nova_firewall_driver': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'firewall_driver', value => $controller_ocata::params::nova_firewall_driver, }
   ###
   do_config { 'nova_use_neutron': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'use_neutron', value => $controller_rocky::params::use_neutron, }
   do_config { 'nova_cpu_allocation_ratio': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'cpu_allocation_ratio', value => $controller_rocky::params::nova_cpu_allocation_ratio, }
   do_config { 'nova_disk_allocation_ratio': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'disk_allocation_ratio', value => $controller_rocky::params::nova_disk_allocation_ratio, }
   do_config { 'nova_ram_allocation_ratio': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'ram_allocation_ratio', value => $controller_rocky::params::nova_ram_allocation_ratio, }
   ### FF DEPRECATED in PIKE:
   #You can safely remove the AggregateCoreFilter, AggregateRamFilter, and AggregateDiskFilter from your [filter_scheduler]enabled_filters and you do not need to replace them with any other core/ram/disk filters. The placement query in the FilterScheduler takes care of the core/ram/disk filtering, so CoreFilter, RamFilter, and DiskFilter are redundant.
   ###
   do_config { 'nova_enabled_filters': conf_file => '/etc/nova/nova.conf', section => 'filter_scheduler', param => 'enabled_filters', value => $controller_rocky::params::enabled_filters, }
   do_config { 'nova_default_schedule_zone': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'default_schedule_zone', value => $controller_rocky::params::nova_default_schedule_zone, }
   do_config { 'nova_scheduler_max_attempts': conf_file => '/etc/nova/nova.conf', section => 'scheduler', param => 'max_attempts', value => $controller_rocky::params::nova_scheduler_max_attempts, }
   do_config { 'nova_host_subset_size': conf_file => '/etc/nova/nova.conf', section => 'filter_scheduler', param => 'host_subset_size', value => $controller_rocky::params::nova_host_subset_size, }
   do_config { 'nova_host_discover_hosts': conf_file => '/etc/nova/nova.conf', section => 'scheduler', param => 'discover_hosts_in_cells_interval', value => $controller_rocky::params::nova_discover_hosts_in_cells_interval, }
   ### FF MODIFIED IN QUEENS [vnc]vncserver_listen --> [vnc]server_listen and [vnc]vncserver_proxyclient_address -->w [vnc]server_proxyclient_address
   #do_config { 'nova_vncserver_listen': conf_file => '/etc/nova/nova.conf', section => 'vnc', param => 'vncserver_listen', value => $controller_ocata::params::vip_pub, }
   #do_config { 'nova_vncserver_proxyclient_address': conf_file => '/etc/nova/nova.conf', section => 'vnc', param => 'vncserver_proxyclient_address', value => $controller_ocata::params::vip_mgmt, }
   do_config { 'nova_vnc_server_listen': conf_file => '/etc/nova/nova.conf', section => 'vnc', param => 'server_listen', value => $controller_rocky::params::vip_pub, }
   do_config { 'nova_vnc_server_proxyclient_address': conf_file => '/etc/nova/nova.conf', section => 'vnc', param => 'server_proxyclient_address', value => $controller_rocky::params::vip_mgmt, 
   ###}
   do_config { 'nova_vnc_enabled': conf_file => '/etc/nova/nova.conf', section => 'vnc', param => 'enabled', value => $controller_rocky::params::vnc_enabled, }
   do_config { 'nova_api_db': conf_file => '/etc/nova/nova.conf', section => 'api_database', param => 'connection', value => $controller_rocky::params::nova_api_db, }

   do_config { 'nova_db': conf_file => '/etc/nova/nova.conf', section => 'database', param => 'connection', value => $controller_rocky::params::nova_db, }
   do_config { 'nova_enabled_apis': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'enabled_apis', value => $controller_rocky::params::enabled_apis, }

   do_config { 'nova_oslo_lock_path': conf_file => '/etc/nova/nova.conf', section => 'oslo_concurrency', param => 'lock_path', value => $controller_rocky::params::nova_oslo_lock_path, }


   do_config { 'nova_memcached_servers': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'memcached_servers', value => $controller_rocky::params::memcached_servers, }
   do_config { 'nova_auth_uri': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'auth_uri', value => $controller_rocky::params::auth_uri, }   
   do_config { 'nova_auth_url': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'auth_url', value => $controller_rocky::params::auth_url, }
   do_config { 'nova_auth_plugin': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'auth_type', value => $controller_rocky::params::auth_type, }
   do_config { 'nova_project_domain_name': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'project_domain_name', value => $controller_rocky::params::project_domain_name, }
   do_config { 'nova_user_domain_name': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'user_domain_name', value => $controller_rocky::params::user_domain_name, }
   do_config { 'nova_project_name': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'project_name', value => $controller_rocky::params::project_name, }
   do_config { 'nova_username': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'username', value => $controller_rocky::params::nova_username, }
   do_config { 'nova_password': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'password', value => $controller_rocky::params::nova_password, }
   do_config { 'nova_cafile': conf_file => '/etc/nova/nova.conf', section => 'keystone_authtoken', param => 'cafile', value => $controller_rocky::params::cafile, }

   do_config { 'nova_inject_password': conf_file => '/etc/nova/nova.conf', section => 'libvirt', param => 'inject_password', value => $controller_rocky::params::nova_inject_password, }
   do_config { 'nova_inject_key': conf_file => '/etc/nova/nova.conf', section => 'libvirt', param => 'inject_key', value => $controller_rocky::params::nova_inject_key, }
   do_config { 'nova_inject_partition': conf_file => '/etc/nova/nova.conf', section => 'libvirt', param => 'inject_partition', value => $controller_rocky::params::nova_inject_partition, }
   ### FF CHANGED IN QUEENS: If using the api_servers option in the [glance] configuration section, the values therein must be URLs. The [glance]api_servers conf option is still supported, but should only be used if you need multiple endpoints and are unable to use a load balancer for some reason. This includes using endpoint_override in favor of api_servers. 
   do_config { 'nova_glance_api_servers': conf_file => '/etc/nova/nova.conf', section => 'glance', param => 'api_servers', value => $controller_rocky::params::glance_api_servers, }
   ###
####neutron config in nova.conf
   # FF  DEPRECATED in ROCKY [neutron]url diventa [neutron]endpoint_override
   #do_config { 'nova_neutron_url': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'url', value => $controller_rocky::params::neutron_url, }
   do_config { 'nova_neutron_endpoint_override': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'endpoint_override', value => $controller_rocky::params::neutron_endpoint_override, }
   ###
   do_config { 'nova_neutron_auth_type': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'auth_type', value => $controller_rocky::params::auth_type, }
   do_config { 'nova_neutron_auth_url': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'auth_url', value => $controller_rocky::params::auth_url, }
   do_config { 'nova_neutron_project_domain_name': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'project_domain_name', value => $controller_rocky::params::project_domain_name, }
   do_config { 'nova_neutron_user_domain_name': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'user_domain_name', value => $controller_rocky::params::user_domain_name, }
   do_config { 'nova_neutron_region_name': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'region_name', value => $controller_rocky::params::region_name, }
   do_config { 'nova_neutron_project_name': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'project_name', value => $controller_rocky::params::project_name, }
   do_config { 'nova_neutron_username': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'username', value => $controller_rocky::params::neutron_username, }
   do_config { 'nova_neutron_password': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'password', value => $controller_rocky::params::neutron_password, }
   do_config { 'nova_neutron_cafile': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'cafile', value => $controller_rocky::params::cafile, }
   do_config { 'nova_service_metadata_proxy': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'service_metadata_proxy', value => $controller_rocky::params::service_metadata_proxy, }
   do_config { 'nova_metadata_proxy_shared_secret': conf_file => '/etc/nova/nova.conf', section => 'neutron', param => 'metadata_proxy_shared_secret', value => $controller_rocky::params::metadata_proxy_shared_secret, }

#########Placement
   do_config { 'nova_placement_auth_type': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'auth_type', value => $controller_rocky::params::auth_type, }
   do_config { 'nova_placement_auth_url': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'auth_url', value => $controller_rocky::params::placement_auth_url, }
   do_config { 'nova_placement_project_domain_name': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'project_domain_name', value => $controller_rocky::params::project_domain_name, }
   do_config { 'nova_placement_user_domain_name': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'user_domain_name', value => $controller_rocky::params::user_domain_name, }
   ### FF DEPRECATED in QUEENS os_region_name --> region_name
   #do_config { 'nova_placement_os_region_name': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'os_region_name', value => $compute_ocata::params::region_name, }
   do_config { 'nova_placement_region_name': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'region_name', value => $compute_rocky::params::region_name, }
   ###
   do_config { 'nova_placement_project_name': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'project_name', value => $controller_rocky::params::project_name, }
   do_config { 'nova_placement_username': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'username', value => $controller_rocky::params::placement_username, }
   do_config { 'nova_placement_password': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'password', value => $controller_rocky::params::placement_password, }
   do_config { 'nova_placement_cafile': conf_file => '/etc/nova/nova.conf', section => 'placement', param => 'cafile', value => $controller_rocky::params::cafile, }
   ### FF ADDED IN PIKE: the Placement API can be set to connect to a specific keystone endpoint interface using the os_interface option in the [placement] section inside nova.conf. This value is not required but can be used if a non-default endpoint interface is desired for connecting to the Placement service. By default, keystoneauth will connect to the “public” endpoint.
   ### FF DEPRECATED IN QUEENS [PLACEMENT]os_interface -->[PLACEMENT]valid_interfaces


#################
  ### DEPRECATED in QUEENS: Nova no longer supports the Block Storage (Cinder) v2 API. Ensure the following configuration options are set properly for Cinder v3:
  #[cinder]/catalog_info - Already defaults to Cinder v3
  #[cinder]/endpoint_template - Not used by default.
  do_config { 'nova_cinder_catalog_info': conf_file => '/etc/nova/nova.conf', section => 'cinder', param => 'catalog_info', value => $controller_rocky::params::nova_cinder_catalog_info, }
  do_config { 'nova_cinder_endpoint_template': conf_file => '/etc/nova/nova.conf', section => 'cinder', param => 'endpoint_template', value => $controller_rocky::params::nova_cinder_endpoint_template, }
  do_config { 'nova_cinder_os_region_name': conf_file => '/etc/nova/nova.conf', section => 'cinder', param => 'os_region_name', value => $controller_rocky::params::region_name, }
#######Proxy headers parsing
  do_config { 'nova_enable_proxy_headers_parsing': conf_file => '/etc/nova/nova.conf', section => 'oslo_middleware', param => 'enable_proxy_headers_parsing', value => $controller_rocky::params::enable_proxy_headers_parsing, }

  do_config_list { "nova_pci_alias":
              conf_file => '/etc/nova/nova.conf',
              section   => 'pci',
              param     => 'alias',
              values    => [ "$controller_rocky::params::pci_alias_1", "$controller_rocky::params::pci_alias_2" ],
            }

  do_config { 'nova_pci_passthrough_whitelist': conf_file => '/etc/nova/nova.conf', section => 'pci', param => 'passthrough_whitelist', value => $controller_rocky::params::pci_passthrough_whitelist, }


# Pare che questi non servano piu`
#   do_config { 'nova_novncproxy_base_url': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'novncproxy_base_url', value => $controller_rocky::params::novncproxy_base_url, }
#   do_config { 'nova_region_name': conf_file => '/etc/nova/nova.conf', section => 'DEFAULT', param => 'os_region_name', value => $controller_rocky::params::region_name, }

######nova_policy and 00-nova-placement are copied from /controller_rocky/files dir       
file {'nova_policy.json':
           source      => 'puppet:///modules/controller_rocky/nova_policy.json',
           path        => '/etc/nova/policy.json',
           backup      => true,
           owner   => root,
           group   => nova,
           mode    => 0640,

         }
      
file {'00-nova-placement-api.conf':
           source      => 'puppet:///modules/controller_rocky/00-nova-placement-api.conf',
           path        => '/etc/httpd/conf.d/00-nova-placement-api.conf',
           ensure      => present,
           backup      => true,
           mode        => 0640,
         }

 
}