# Collect coverage stats and send to Codecov.

cd(Pkg.dir("AnonymousTypes"))
Pkg.add("Coverage")

import Coverage: Codecov
Codecov.submit(Codecov.process_folder())
