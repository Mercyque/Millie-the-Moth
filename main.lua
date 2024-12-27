MothsAflame = include("scripts_ma.koi.ksil"):SuperRegisterMod("Moths Aflame", "scripts_ma.koi", {
    --
})

for _, v in ipairs({
    "enums",
}) do
    include("scripts_ma.constants." .. v)
end

for _, v in ipairs({
    "mittle",
}) do
    include("scripts_ma.characters." .. v)
end