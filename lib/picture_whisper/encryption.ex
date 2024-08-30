defmodule PictureWhisper.Encryption do
  def encrypt(plaintext) do
    secret_key = get_secret_key()
    iv = :crypto.strong_rand_bytes(16)
    plaintext = pad(plaintext, 16)
    ciphertext = :crypto.crypto_one_time(:aes_256_cbc, secret_key, iv, plaintext, true)
    Base.encode64(iv <> ciphertext)
  end

  def decrypt(ciphertext) do
    secret_key = get_secret_key()
    {:ok, decoded} = Base.decode64(ciphertext)
    <<iv::binary-16, ciphertext::binary>> = decoded
    plaintext = :crypto.crypto_one_time(:aes_256_cbc, secret_key, iv, ciphertext, false)
    unpad(plaintext)
  end

  defp get_secret_key do
    secret_key_base = Application.get_env(:picture_whisper, PictureWhisperWeb.Endpoint)[:secret_key_base]
    :crypto.hash(:sha256, secret_key_base)
  end

  defp pad(data, block_size) do
    to_add = block_size - rem(byte_size(data), block_size)
    data <> :binary.copy(<<to_add>>, to_add)
  end

  defp unpad(data) do
    to_remove = :binary.last(data)
    :binary.part(data, 0, byte_size(data) - to_remove)
  end
end
