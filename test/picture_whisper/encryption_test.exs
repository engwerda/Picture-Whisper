defmodule PictureWhisper.EncryptionTest do
  use ExUnit.Case, async: true
  alias PictureWhisper.Encryption

  describe "encrypt/1 and decrypt/1" do
    test "encrypts and decrypts plaintext correctly" do
      plaintext = "Hello, World!"
      encrypted = Encryption.encrypt(plaintext)
      decrypted = Encryption.decrypt(encrypted)
      assert decrypted == plaintext
    end

    test "encrypts the same plaintext to different ciphertexts" do
      plaintext = "Hello, World!"
      encrypted1 = Encryption.encrypt(plaintext)
      encrypted2 = Encryption.encrypt(plaintext)
      assert encrypted1 != encrypted2
    end

    test "handles empty string" do
      plaintext = ""
      encrypted = Encryption.encrypt(plaintext)
      decrypted = Encryption.decrypt(encrypted)
      assert decrypted == plaintext
    end

    test "handles long plaintext" do
      plaintext = String.duplicate("a", 1000)
      encrypted = Encryption.encrypt(plaintext)
      decrypted = Encryption.decrypt(encrypted)
      assert decrypted == plaintext
    end
  end

  describe "get_secret_key/0" do
    test "returns a 32-byte binary" do
      secret_key = Encryption.get_secret_key()
      assert byte_size(secret_key) == 32
    end

    test "returns the same key for multiple calls" do
      key1 = Encryption.get_secret_key()
      key2 = Encryption.get_secret_key()
      assert key1 == key2
    end
  end

  describe "pad/2 and unpad/1" do
    test "pads and unpads data correctly" do
      data = "Hello, World!"
      padded = Encryption.pad(data, 16)
      assert rem(byte_size(padded), 16) == 0
      unpadded = Encryption.unpad(padded)
      assert unpadded == data
    end

    test "handles data that is already a multiple of block size" do
      data = String.duplicate("a", 16)
      padded = Encryption.pad(data, 16)
      assert byte_size(padded) == 32
      unpadded = Encryption.unpad(padded)
      assert unpadded == data
    end
  end
end
