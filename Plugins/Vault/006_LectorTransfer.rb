#===============================================================================
# 📊 Lector de Transfer.dat
#===============================================================================

module TransferInspector
  module_function

  def read_transfer_info
    path = PokemonVault.transfer_path

    if !File.exist?(path)
      return nil
    end

    begin
      data = Marshal.load(File.binread(path))

      source = data[:source_game] rescue "UNKNOWN"
      target = data[:target_game] rescue "UNKNOWN"

      return {
        source: source,
        target: target
      }

    rescue
      return nil
    end
  end

end

#===============================================================================
# 📊 Lector rápido de transfer.dat (para eventos)
#===============================================================================

def pbLeeMiTransferPorfavor
  path = PokemonVault.transfer_path
  return nil if !File.exist?(path)

  data = Marshal.load(File.binread(path)) rescue nil
  return nil if !data

  return [data[:source_game], data[:target_game]]
end

def pbMostrarInfoTransfer
  info = pbLeeMiTransferPorfavor

  if info
    pbMessage("Origen: #{info[0]}")
    pbMessage("Destino: #{info[1]}")
  else
    pbMessage("No hay transfer.dat")
  end
end