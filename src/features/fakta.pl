


maks_party(4).
/* === POKEMON COMMON === */
pokemon_common(charmander).
pokemon_common(squirtle).
pokemon_common(pidgey).
pokemon_evolved(charmeleon).
pokemon_evolved(wartortle).

starter_tersedia(1, charmander).
starter_tersedia(2, squirtle).
starter_tersedia(3, pidgey).

starter_tersedia([charmander, squirtle, pidgey]).

/* === POKEMON (nama, rarity, tipe, HP, ATK, DEF, skill1, skill2, evolusi, lvl evolusi) === */
pokemon(charmander, common, fire, 35, 15, 10, scratch, ember, charmeleon, 15).
pokemon(squirtle, common, water, 40, 12, 15, tackle, water_gun, wartortle, 15).
pokemon(pidgey, common, flying, 30, 14, 10, tackle, gust, none, none).
pokemon(charmeleon, common, fire, 45, 20, 15, ember, fire_spin, none, none).
pokemon(wartortle, common, water, 50, 17, 20, water_gun, bubble, none, none).
pokemon(pikachu, rare, electric, 30, 16, 10, thunder_shock, quick_attack, none, none).
pokemon(geodude, rare, rock, 30, 20, 25, tackle, rock_throw, none, none).
pokemon(snorlax, epic, normal, 70, 30, 20, tackle, rest, none, none).
pokemon(articuno, legendary, ice, 60, 28, 35, gust, ice_shard, none, none).
pokemon(mewtwo, legendary, psychic, 250, 30, 25, psychic_blast, mind_shock, none, none).

/* === SKILL === */
skill(tackle, normal, 35, none).
skill(scratch, normal, 35, none).
skill(ember, fire, 40, burn_10).
skill(water_gun, water, 40, none).
skill(gust, flying, 30, none).
skill(fire_spin, fire, 35, burn(3, 2)).
skill(bubble, water, 30, lower_atk(3)).
skill(thunder_shock, electric, 40, paralyze_20).
skill(quick_attack, normal, 30, none).
skill(rock_throw, rock, 50, none).
skill(rest, normal, 0, heal_40_percent).
skill(ice_shard, ice, 40, none).
skill(normal, normal, 5, none).
skill(psychic_blast, psychic, 25, confused_20_percent).
skill(mind_shock, psychic, 20, area_damage).

/* === EFEKTIFITAS TYPE === */
efektif(fire, ice, 1.5).
efektif(water, fire, 1.5).
efektif(water, rock, 1.5).
efektif(electric, water, 1.5).
efektif(electric, flying, 1.5).
efektif(rock, fire, 1.5).
efektif(rock, flying, 1.5).
efektif(rock, ice, 1.5).
efektif(ice, flying, 1.5).
efektif(psychic, fighting, 1.5).
efektif(psychic, poison, 1.5).

efektif(fire, water, 0.5).
efektif(fire, rock, 0.5).
efektif(fire, fire, 0.5).
efektif(water, electric, 0.5).
efektif(water, water, 0.5).
efektif(electric, electric, 0.5).
efektif(electric, rock, 0.5).
efektif(flying, electric, 0.5).
efektif(flying, rock, 0.5).
efektif(flying, ice, 0.5).
efektif(rock, water, 0.5).
efektif(rock, rock, 0.5).
efektif(ice, fire, 0.5).
efektif(ice, rock, 0.5).
efektif(ice, water, 0.5).
efektif(ice, ice, 0.5).
efektif(normal, rock, 0.5).
efektif(psychic, psychic, 0.5).
efektif(psychic, steel, 0.5).

/* === DEKLARASI MOVE === */
init_moves :-
    retractall(move_count(_)),
    assertz(move_count(0)).

init_level :-
    retractall(level_count(_)),
    assertz(level_count(0)).

rarity_catch_rate(common, 40).
rarity_catch_rate(rare, 30).
rarity_catch_rate(epic, 25).
rarity_catch_rate(legendary, 20).