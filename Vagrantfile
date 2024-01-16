Vagrant.configure(2) do |config|
  config.vm.provider 'libvirt' do |libvirt, override|
    libvirt.memory = 2048

    if File.exist?('/dev/kvm')
      libvirt.driver = 'kvm'
    else
      libvirt.driver = 'qemu'
    end

    libvirt.machine_type = 'q35'

    libvirt.disk_driver :cache => 'writeback', :discard => 'unmap'

    if Vagrant.has_plugin?('vagrant-libvirt', '> 0.5.3')
      libvirt.channel :type => 'unix', :target_name => 'org.qemu.guest_agent.0', :target_type => 'virtio'
      libvirt.qemu_use_agent = true
    end

    libvirt.graphics_type = 'spice'
    libvirt.channel :type => 'spicevmc', :target_name => 'com.redhat.spice.0', :target_type => 'virtio'

    # https://github.com/vagrant-libvirt/vagrant-libvirt/pull/1386
    if Vagrant.has_plugin?('vagrant-libvirt', '>= 0.7.0')
      libvirt.video_accel3d = true
      libvirt.video_type = 'virtio'
      libvirt.graphics_autoport = 'no'
      if Vagrant.has_plugin?('vagrant-libvirt', '>= 0.8.0')
        libvirt.graphics_port = nil
        libvirt.graphics_ip = nil
      else
        libvirt.graphics_ip = 'none'
        libvirt.graphics_port = 0
      end
    end
  end

  config.vm.synced_folder '.', '/vagrant', disabled: true
end
