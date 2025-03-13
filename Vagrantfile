Vagrant.configure(2) do |config|
  config.vm.provider :libvirt do |libvirt; box_dir|
    libvirt.memory = 4096

    if File.exist?('/dev/kvm')
      libvirt.driver = 'kvm'
    else
      libvirt.driver = 'qemu'
    end

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
      if not Vagrant.has_plugin?('vagrant-libvirt', '>= 0.11.0')
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

    box_dir = File.dirname(File.expand_path(__FILE__))

    libvirt.nvram = File.join(box_dir, 'efivars.fd')
    libvirt.loader = File.join(box_dir, Dir.glob('OVMF_CODE*', base: box_dir).first)
    libvirt.machine_type = 'pc-q35-8.2'
  end

  config.vm.synced_folder '.', '/vagrant', disabled: true

  if /^alpine\d+$/ =~ '{{build_name}}'
    config.ssh.sudo_command = 'doas -n -u root %c'
  end
end
