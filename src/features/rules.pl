

modifier_tipe(TipeSkill, TipeTarget, 1.0) :- \+ efektif(TipeSkill, TipeTarget, _).
modifier_tipe(TipeSkill, TipeTarget, Modifier) :- efektif(TipeSkill, TipeTarget, Modifier).


/* === UTILITY === */
party_penuh(Pemain) :-
    party(Pemain, List, _Level),
    length(List, Len),
    Len >= 4.

is_common(Pokemon) :-
    pokemon(Pokemon, common, _, _, _, _, _, _, _, _).

memiliki(Pemain, Pokemon) :-
    party(Pemain, List),
    member(Pokemon, List).

skill_aktif(Pokemon, Level, Skill1, Skill2) :-
    pokemon(Pokemon, _, _, _, _, _, SkillAwal, SkillLanjut, _, EvolusiLevel),
    Skill1 = SkillAwal,
    (EvolusiLevel \= none, Level >= EvolusiLevel -> Skill2 = SkillLanjut
    ; Level >= 10 -> Skill2 = SkillLanjut ).

damage(Attacker, Defender, SkillName, Damage) :-
    pokemon(Attacker, _, _, _, ATK, _, _, _, _, _),
    pokemon(Defender, _, TipeD, _, _, DEF, _, _, _, _),
    skill(SkillName, TipeSkill, Power, _),
    modifier_tipe(TipeSkill, TipeD, Modifier),
    DEF > 0,
    TempD is (Power * ATK) / DEF * (1/3),
    Damage is TempD * Modifier.

evolve(Pokemon, Evo) :-
    pokemon(Pokemon, _, _, _, _, _, _, _, Evo, LevelEvo),
    Evo \= none,
    level_pokemon(Pokemon, L),
    L >= LevelEvo.

/* ===EXP=== */
/* === EXP DAN LEVELING === */
base_exp_rarity(common, 20).
base_exp_rarity(rare, 30).
base_exp_rarity(epic, 40).
base_exp_rarity(legendary, 50).

base_exp_given(common, 10).
base_exp_given(rare, 20).
base_exp_given(epic, 30).
base_exp_given(legendary, 40).

exp_naik_level(Pokemon, LevelSekarang, ExpDibutuhkan) :-
    pokemon(Pokemon, Rarity, _, _, _, _, _, _, _, _),
    base_exp_rarity(Rarity, Base),
    ExpDibutuhkan is Base * LevelSekarang.

exp_didapat(PokemonKalah, LevelKalah, Exp) :-
    pokemon(PokemonKalah, Rarity, _, _, _, _, _, _, _, _),
    base_exp_given(Rarity, Base),
    Exp is Base + (LevelKalah * 2).

naik_level([Pokemon, Level, HP, ATK, DEF, EXP], [FinalPokemon, FinalLevel, FinalHP, FinalATK, FinalDEF, FinalEXP]) :-
    exp_naik_level(Pokemon, Level, ExpNaik),
    EXP >= ExpNaik,
    Level1 is Level + 1,
    HP1 is HP + 2,
    ATK1 is ATK + 1,
    DEF1 is DEF + 1,
    SisaEXP is EXP - ExpNaik,
    pokemon(Pokemon, _, _, _, _, _, _, _, Evolusi, LvlEvo),
    ( Evolusi \= none, Level1 >= LvlEvo ->
        pokemon(Evolusi, _, _, _, _, _, _Skill1Baru, _Skill2Baru, _, _),
        write(Pokemon), write(' berevolusi menjadi '), write(Evolusi), write('!'), nl,
        NewPokemon = Evolusi
    ;
        NewPokemon = Pokemon
    ),

    naik_level([NewPokemon, Level1, HP1, ATK1, DEF1, SisaEXP], [FinalPokemon, FinalLevel, FinalHP, FinalATK, FinalDEF, FinalEXP]).

naik_level(Status, Status).

tambah_exp([Pokemon, Level, HP, ATK, DEF, EXP], TambahanEXP, [NewPokemon,NewLevel,NewHP,NewATK,NewDEF,NewEXP]) :-
    enemy_pokemon(PokeE, LevelE, _, _HPfE, _ATKnE, _ATKfE, _DEFnE, _DEFfE),
    exp_didapat(PokeE, LevelE, TambahanEXP),
    EXPBaru is EXP + TambahanEXP,
    naik_level([Pokemon, Level, HP, ATK, DEF, EXPBaru], [NewPokemon,NewLevel,NewHP,NewATK,NewDEF,NewEXP]).

/* ===HEAL=== */
heal_pokemon :-
    pemain(Pemain),

    forall(party(Pemain, Poke, Lv, HN, HF, AN, AF, DN, DF, EXP),
        (
            HN1 is min(HF, HN + round(0.2 * HF)),
            AN1 is min(AF, AN + round(0.2 * AF)),
            DN1 is min(DF, DN + round(0.2 * DF)),
            retract(party(Pemain, Poke, Lv, HN, HF, AN, AF, DN, DF, EXP)),
            asserta(party(Pemain, Poke, Lv, HN1, HF, AN1, AF, DN1, DF, EXP))
        )
    ),

    forall(
        isi_tas(Pemain, Slot, item_pokeball(pokemon_tas(Poke, Jenis, Lv, HN, HF, AN, AF, DN, DF))),
        (
            HN1 is min(HF, HN + round(0.2 * HF)),
            AN1 is min(AF, AN + round(0.2 * AF)),
            DN1 is min(DF, DN + round(0.2 * DF)),
            retract(isi_tas(Pemain, Slot, item_pokeball(pokemon_tas(Poke, Jenis, Lv, HN, HF, AN, AF, DN, DF)))),
            asserta(isi_tas(Pemain, Slot, item_pokeball(pokemon_tas(Poke, Jenis, Lv, HN1, HF, AN1, AF, DN1, DF))))
        )
    ),

    write('Semua Pokemon mendapatkan sedikit pemulihan.'), nl.


random_member(Elem, List) :-
    length(List, Len),
    Len > 0,
    random(R),
    Index is floor(R * Len),
    nth0(Index, List, Elem).

/* ===MOVE=== */
add_move :-
    move_count(N),
    N < 20,
    N1 is N + 1,
    retract(move_count(N)),
    assertz(move_count(N1)),
    format('Langkah ke-~w dilakukan.~n', [N1]),
    ( N1 =:= 20 -> fight_boss ; true ).

add_move :-
    move_count(20),
    format('Langkah sudah 20, saatnya lawan bos!~n'),
    fight_boss.

/* ===STATUS=== */
hitung_stat_musuh(Pokemon, Level, HP, ATK, DEF) :-
    pokemon(Pokemon, _, _, BaseHP, BaseATK, BaseDEF, _, _, _, _),
    HP  is BaseHP + (Level - 1) * 2,
    ATK is BaseATK + (Level - 1) * 1,
    DEF is BaseDEF + (Level - 1) * 1.

tampilkan_status_musuh(Pokemon, Level) :-
    pemain(Nama),
    posisi_pemain(Nama, X, Y),
    ( pokemon_bersembunyi(X, Y, level_pokemon(_Pokemon, _Level)) ->
        hitung_stat_musuh(Pokemon, Level, HP, ATK, DEF),
        write('Musuh di hadapanmu!'), nl,
        write('Nama  : '), write(Pokemon), nl,
        write('Level : '), write(Level), nl,
        write('HP    : '), write(HP), nl,
        write('ATK   : '), write(ATK), nl,
        write('DEF   : '), write(DEF), nl
    ;
        write('Tidak ada musuh di hadapanmu.'), nl
    ).


stat_musuh(Pokemon, Level) :-
    hitung_stat_musuh(Pokemon, Level, HP, ATK, DEF),
    format("HP: ~w, ATK: ~w, DEF: ~w~n", [HP, ATK, DEF]).

set_status_awal(Pokemon, Level, HPnow, HPfull, ATKnow, ATKfull, DEFnow, DEFfull) :-
    pokemon(Pokemon, _, _, BaseHP, BaseATK, BaseDEF, _, _, _, _),
    HPfull is BaseHP + (Level - 1) * 2,
    ATKfull is BaseATK + (Level - 1) * 1,
    DEFfull is BaseDEF + (Level - 1) * 1,
    HPnow = HPfull,
    ATKnow = ATKfull,
    DEFnow = DEFfull.


punya_pokeball_kosong(Pemain, Slot) :-
    isi_tas(Pemain, Slot, item_pokeball(kosong)).

/* ===LEVEL=== */
/*Agar level pokemon semakin lama semakin besar*/
add_level :-
    level_count(N),
    ( N < 10 ->
        N1 is N + 1,
        retract(level_count(N)),
        assertz(level_count(N1))
    ;
        true 
    ).

print_level :-
    level_count(N),
    write('total level :  '), write(N), nl.

/* Boss */
fight_boss :-
    nl,
    write('============================================='), nl,
    write('Kamu telah mencapai akhir perjalananmu.'), nl,
    write('Sesosok bayangan besar muncul di hadapanmu...'), nl,
    sleep(2),
    write('Boss Legendaris, MEWTWO, menantangmu!'), nl,
    write('============================================='), nl,
    
    retractall(enemy_pokemon(_, _, _, _, _, _, _, _)),
    asserta(enemy_pokemon(mewtwo, 20, 250, 250, 30, 30, 25, 25)),
    
    retractall(in_battle(_)),
    asserta(in_battle(boss)), 
    
    write('Persiapkan dirimu untuk pertarungan terakhir!'), nl,
    pilih_pokemon_utama_boss, 
    tampilkan_status_battle,
    aksi_battle_boss.

pilih_pokemon_utama_boss :-
    pemain(Nama),
    write('Pilih Pokemon utama dari party untuk melawan Boss:'), nl,
    findall((Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP),
        party(Nama, Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP),
        Daftar),
    (   Daftar = [] ->
        write('Tidak ada Pokemon di party!'), nl, end_game(lose)
    ;
        tampilkan_party(Daftar, 1), 
        write('Masukkan nomor pilihan: '), read(Idx),
        (   nth1(Idx, Daftar, (Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP)), HP > 0 ->
            retractall(party_pokemon(_, _, _, _, _, _, _, _, _)),
            asserta(party_pokemon(Poke, Lv, HP, HF, ATK, AF, DEF, DF, EXP)),
            format('~w, maju!~n', [Poke])
        ;
            write('Pilihan tidak valid atau Pokemon sudah pingsan. Coba lagi.'), nl,
            pilih_pokemon_utama_boss
        )
    ).

aksi_battle_boss :-
    in_battle(boss),
    party_pokemon(_, _, HP, _, _, _, _, _, _), 
    HP > 0,
    nl,
    write('--- Giliranmu vs MEWTWO ---'), nl,
    write('1. Attack'), nl,
    write('2. Defend'), nl,
    write('Masukkan pilihan (1/2): '),
    catch(read(Pilihan), _, Pilihan = -1),
    (
        Pilihan = 1 -> aksi_attack_boss;
        Pilihan = 2 -> aksi_defend_boss;
        write('Pilihan tidak valid. Coba lagi.'), nl, aksi_battle_boss
    ).

aksi_attack_boss :-
    party_pokemon(PokeP, LevelP, _, _, _, _, _, _, _),
    write('Pilih serangan:'), nl,
    (   skill_aktif(PokeP, LevelP, [Skill1, Skill2]) ->
        format('1. ~w~n2. ~w~n', [Skill1, Skill2]),
        read(N),
        ( N == 1 -> SkillPilihan = Skill1 ; N == 2 -> SkillPilihan = Skill2 )
    ;   skill_aktif(PokeP, LevelP, [Skill1]) ->
        format('1. ~w~n', [Skill1]),
        read(N),
        ( N == 1 -> SkillPilihan = Skill1 )
    ),
    (
        var(SkillPilihan) -> write('Pilihan skill tidak valid.'), nl, aksi_attack_boss
        ;
        damage_party_to_enemy(SkillPilihan, Damage),
        enemy_pokemon(PokeE, LvE, HPnE, HPfE, ATKnE, ATKfE, DEFnE, DEFfE),
        HPnE2 is max(0, HPnE - Damage),
        retractall(enemy_pokemon(_,_,_,_,_,_,_,_)),
        asserta(enemy_pokemon(PokeE, LvE, HPnE2, HPfE, ATKnE, ATKfE, DEFnE, DEFfE)),
        format('~w menggunakan ~w dan memberikan ~w damage pada Mewtwo!~n', [PokeP, SkillPilihan, Damage]),
        tampilkan_status_battle,
        (HPnE2 =< 0 -> end_game(win) ; giliran_boss)
    ).

aksi_defend_boss :-
    retractall(defending(_)),
    asserta(defending(yes)),
    write('Pokemonmu bersiap bertahan!'), nl,
    giliran_boss.

giliran_boss :-
    sleep(1),
    nl, write('--- Giliran MEWTWO ---'), nl,
    enemy_pokemon(PokeE, _, _, _, _, _, _, _),

    random(R),
    Aksi is floor(R * 3) + 1,
    pokemon(PokeE, _, _, _, _, _, Skill1, Skill2, _, _),

    ( Aksi = 1 -> SkillBoss = normal ;
      Aksi = 2 -> SkillBoss = Skill1 ;
      Aksi = 3 -> SkillBoss = Skill2
    ),

    damage_enemy_to_party(SkillBoss, DamageRaw),

    (   retract(defending(yes)) ->
        Damage is round(DamageRaw * 0.7),
        write('Mewtwo menyerang, tetapi pertahananmu mengurangi dampaknya!'), nl
    ;
        Damage = DamageRaw
    ),

    party_pokemon(PokeP, LvP, HPnP, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP), 
    HPnP2 is max(0, HPnP - Damage),
    retractall(party_pokemon(_,_,_,_,_,_,_,_,_)),
    asserta(party_pokemon(PokeP, LvP, HPnP2, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP)),

    format('Mewtwo menggunakan ~w dan memberikan ~w damage!~n', [SkillBoss, Damage]),
    tampilkan_status_battle,

    (   HPnP2 =< 0 ->
        write('Pokemonmu pingsan!'), nl,
        pemain(Nama),
        retract(party(Nama, PokeP, _, _, _, _, _, _, _, _)),
        asserta(party(Nama, PokeP, LvP, HPnP2, HPfP, ATKnP, ATKfP, DEFnP, DEFfP, EXP)),
        ganti_pokemon_utama_boss
    ;
        aksi_battle_boss
    ).

ganti_pokemon_utama_boss :-
    pemain(Nama),
    findall(P, (party(Nama, P, _, HP, _, _, _, _, _, _), HP > 0), PokemonHidup),
    (   PokemonHidup = [] ->
        write('Semua Pokemonmu telah dikalahkan...'), nl,
        end_game(lose)
    ;
        write('Pilih Pokemon pengganti:'), nl,
        pilih_pokemon_utama_boss,
        tampilkan_status_battle,
        aksi_battle_boss
    ).
    
end_game(win) :-
    nl, write('============================================='), nl,
    write('Kamu berhasil mengalahkan MEWTWO!'), nl,
    write('Kamu adalah sang juara!'), nl,
    write('============================================='), nl,
    retractall(in_battle(_)),
    halt. 

end_game(lose) :-
    nl, write('============================================='), nl,
    write('Kamu Kalah.....'), nl,
    write('Perjalananmu berakhir di sini. Coba lagi lain kali! (NOOB)'), nl,
    write('============================================='), nl,
    retractall(in_battle(_)),
    halt. 