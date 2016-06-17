# ********** Copyright 2016 Viacom, Inc. Apache 2.0 **********

module Git
  class Lib
    def stash_pop(id = nil)
      if id
        command('stash pop', [id])
      else
        command('stash pop')
      end
    end
    def stash_drop(id = nil)
      if id
        command('stash drop', [id])
      else
        command('stash drop')
      end
    end
  end
end
