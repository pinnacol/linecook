def self.extended(base)
  if os = base.attrs['linecook']['os']
    base.helper os
  end

  if shell = base.attrs['linecook']['shell']
    base.helper shell
  end

  super
end
