MothsAflame = include("scripts_ma.koi.ksil"):SuperRegisterMod("Moths Aflame", "scripts_ma.koi", {
    LastAimUtility = true,
    Scheduler = true,
})

MothsAflame.ChargeBar = include("scripts_ma.chargebar")

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

for _, v in ipairs({
    "cantrip",
}) do
    include("scripts_ma.spells." .. v)
end