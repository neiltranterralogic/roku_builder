# ********** Copyright 2016 Viacom, Inc. Apache 2.0 **********

module Git
  class Stashes
    def pop(index=nil)
      @base.lib.stash_pop(index)
    end
    def drop(index=nil)
      @base.lib.stash_drop(index)
    end
  end
end
