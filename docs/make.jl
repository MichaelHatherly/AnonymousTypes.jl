using Documenter, AnonymousTypes

makedocs(
    modules = AnonymousTypes,
    clean   = false,
)

deploydocs(
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material"),
    repo = "github.com/MichaelHatherly/AnonymousTypes.jl.git",
)
