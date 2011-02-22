require 'linecook/commands/vbox_command'

module Linecook
  module Commands
    
    # ::desc take a vm snapshop
    #
    # Takes the specified snapshot of one or more VirtualBox virtual machines.
    # By default all virtual machines configured in config/ssh will have a
    # snapshot taken.  If the snapshot name is already taken, the previous
    # snapshot will be renamed.
    #
    # Snapshot can also reset a hierarchy of renamed snapshots using the
    # --reset flag. For example, if there exists a snapshot 'CURRENT' then
    # these command will leave you with snapshots CURRENT_0 (the original),
    # CURRENT_1, and CURRENT (the latest):
    #
    #   linecook snapshot CURRENT
    #   linecook snapshot CURRENT
    #
    # To reset:
    #
    #   liencook snapshot --reset CURRENT
    #
    # After which there will only be a single 'CURRENT' snapshot, which
    # corresponds to the original snapshot.
    #
    class Snapshot < VboxCommand
      config :reset, false, :long => :reset, &c.flag  # reset a snapshot
      
      def process(snapshot, *vm_names)
        each_vm_name(vm_names) do |vm_name|
          if reset
            reset_snapshot(vm_name, snapshot)
          else
            snapshot(vm_name, snapshot)
          end
        end
      end
      
      def parse_snapshots(vm_name)
        info = `VBoxManage -q showvminfo #{vm_name}`
        snapshots = {}
        
        stack = [{}]
        parent  = nil
        
        info.each_line do |line|
          next unless line =~ /^(\s+)Name\: (.*?) \(/
          depth = $1.length / 3
          name = $2
          
          if depth > stack.length
            stack.push stack.last[parent]
          elsif depth < stack.length
            stack.pop
          end
          
          snapshot = {}
          snapshots[name]  = snapshot
          stack.last[name] = snapshot
          parent = name
        end
        
        snapshots
      end
      
      def reset_snapshot(vm_name, snapshot)
        stop(vm_name) if running?(vm_name)
        
        snapshot = snapshot.upcase
        restore(vm_name, snapshot)
        
        snapshots = parse_snapshots(vm_name)
        parent = snapshots.keys.select {|key| key =~ /\A#{snapshot}(?:_\d+)\z/ }.first
        parent ||= snapshot
        
        children = snapshots[parent]
        children.each do |key, value|
          inside_out_each(key, value) do |child|
            sh! "VBoxManage -q snapshot #{vm_name} delete #{child}"
          end
        end
        
        unless parent == snapshot
          sh! "VBoxManage -q snapshot #{vm_name} edit #{parent} --name #{snapshot}"
        end
      end
      
      def snapshot(vm_name, snapshot)
        snapshot = snapshot.upcase
        snapshots = parse_snapshots(vm_name)
        
        count = snapshots.keys.grep(/\A#{snapshot}(?:_|\z)/).length
        if count > 0
          sh! "VBoxManage -q snapshot #{vm_name} edit #{snapshot} --name #{snapshot}_#{count - 1}"
        end
        
        sh! "VBoxManage -q snapshot #{vm_name} take #{snapshot}"
      end
      
      private
      
      def inside_out_each(key, value, &block) # :nodoc:
        value.each_pair do |k, v|
          inside_out_each(k, v, &block)
        end
        
        yield(key)
      end
    end
  end
end