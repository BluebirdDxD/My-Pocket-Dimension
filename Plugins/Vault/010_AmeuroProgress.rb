def pbUpdateAmeuroProgress
  all = pbGetAllPokemon

  all.each do |pkmn|
    next if !pkmn

    begin
      species = pkmn.species
      origin  = pkmn.obtain_text.to_s.downcase

      next if !origin.include?("ameuro")

      case species
      when :BULBASAUR
        $game_switches[203] = true
      when :CHIMCHAR
        $game_switches[204] = true
      when :POPPLIO
        $game_switches[205] = true
      when :POMMEL
        $game_switches[207] = true
      when :ZIGZAGOON
        $game_switches[208] = true
      when :FLYGER
        $game_switches[209] = true
      when :MUSCIBEAT
        $game_switches[210] = true
      end

    rescue
    end
  end
end

#######################################################################################

def pbUpdateKojumiProgress
  all = pbGetAllPokemon

  all.each do |pkmn|
    next if !pkmn

    begin
      species = pkmn.species
      origin  = pkmn.obtain_text.to_s.downcase

      next if !origin.include?("kojumi")

      case species
      when :SPOLE
        $game_switches[403] = true
      when :BOLAVA
        $game_switches[404] = true
      when :STARQUA
        $game_switches[405] = true
      when :OHOS
        $game_switches[407] = true
      when :SKITTY
        $game_switches[408] = true
      when :TOGEPI
        $game_switches[409] = true
      when :UWIKI
        $game_switches[410] = true
      when :ZAPCHIK
        $game_switches[413] = true
      when :RELIKEVER
        $game_switches[414] = true
      when :KIDDLECH
        $game_switches[415] = true
      when :PANGOLAND
        $game_switches[416] = true
      when :SLUGMA
        $game_switches[418] = true
      when :ROLYCOLY
        $game_switches[419] = true
      when :CHARCADET
        $game_switches[420] = true
      when :NINCADA
        $game_switches[422] = true
      when :NYMBLE
        $game_switches[423] = true
      when :DUSTOX
        $game_switches[424] = true
      when :CRISSALIDRA
        $game_switches[425] = true
      when :SKIMMICE
        $game_switches[427] = true
      when :CARROOKIE
        $game_switches[428] = true
      when :CLEFAIRY
        $game_switches[429] = true
      when :SYRIPHONE
        $game_switches[430] = true
      when :FLAMBEAR
        $game_switches[432] = true
      when :HOOTHOOT
        $game_switches[433] = true
      when :MUNNA
        $game_switches[434] = true
      when :APPLIN
        $game_switches[435] = true
      when :THIEVUL
        $game_switches[436] = true
      when :PIKACHU
        $game_switches[438] = true
      when :GROWLITHE
        $game_switches[439] = true
      when :ROUSWILE
        $game_switches[440] = true
      when :FUTALE
        $game_switches[441] = true
      when :NACLI
        $game_switches[443] = true
      when :DRILBUR
        $game_switches[444] = true
      when :CARKOL
        $game_switches[445] = true
      when :AUTOMINEUR
        $game_switches[446] = true
      when :MINIOR
        $game_switches[448] = true
      when :EXSEEDUTE
        $game_switches[449] = true
      when :TANGEL
        $game_switches[450] = true
      when :FEEBAS
        $game_switches[451] = true
      when :STONJORII
        $game_switches[452] = true
      when :DUNSPARCE
        $game_switches[454] = true
      when :PERISOL
        $game_switches[455] = true
      when :CORVISQUIRE
        $game_switches[456] = true
      when :KLAWF
        $game_switches[457] = true
      end
    rescue
    end
  end
end