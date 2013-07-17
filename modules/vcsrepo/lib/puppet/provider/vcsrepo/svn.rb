require File.join(File.dirname(__FILE__), '..', 'vcsrepo')

Puppet::Type.type(:vcsrepo).provide(:svn, :parent => Puppet::Provider::Vcsrepo) do
  desc "Supports Subversion repositories"

  optional_commands :svn      => 'svn',
                    :svnadmin => 'svnadmin'

  has_features :filesystem_types, :reference_tracking, :basic_auth

  def create
    if !@resource.value(:source)
      create_repository(@resource.value(:path))
    else
      checkout_repository(@resource.value(:source),
                          @resource.value(:path),
                          @resource.value(:revision))
    end
    update_owner
  end

  def working_copy_exists?
    File.directory?(File.join(@resource.value(:path), '.svn'))
  end

  def exists?
    working_copy_exists?
  end

  def destroy
    FileUtils.rm_rf(@resource.value(:path))
  end

  def latest?
    at_path do
      if self.revision < self.latest then
        return false
      else
        return true
      end
    end
  end

  def buildargs
    args = ['--non-interactive']
    if @resource.value(:basic_auth_username) && @resource.value(:basic_auth_password)
      args.push('--username', @resource.value(:basic_auth_username))
      args.push('--password', @resource.value(:basic_auth_password))
      args.push('--no-auth-cache')
    end

    if @resource.value(:force)
      args.push('--force')
    end

    return args
  end

  def latest
    args = buildargs.push('info', '-r', 'HEAD')
    at_path do
      svn(*args)[/^Last Changed Rev:\s+(\d+)/m, 1]
    end
  end

  def revision
    args = buildargs.push('info')
    at_path do
      svn(*args)[/^Last Changed Rev:\s+(\d+)/m, 1]
    end
  end

  def revision=(desired)
    args = buildargs.push('update', '-r', desired)
    at_path do
      svn(*args)
    end
    update_owner
  end

  private

  def checkout_repository(source, path, revision)
    args = buildargs.push('checkout')
    if revision
      args.push('-r', revision)
    end
    args.push(source, path)
    svn(*args)
  end

  def create_repository(path)
    args = ['create']
    if @resource.value(:fstype)
      args.push('--fs-type', @resource.value(:fstype))
    end
    args << path
    svnadmin(*args)
  end

  def update_owner
    if @resource.value(:owner) or @resource.value(:group)
      set_ownership
    end
  end
end
