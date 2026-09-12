# The webpush gem (1.1.0) builds its EC keys by mutating an already-generated
# OpenSSL::PKey::EC in place (generate_key, public_key=, private_key=). OpenSSL
# 3.0's provider-backed keys are immutable once created, so every VapidKey and
# the per-message ECDH key in Encryption#encrypt raise
# "OpenSSL::PKey::PKeyError: pkeys are immutable on OpenSSL 3.0". Both are
# patched here to build complete keys up front instead of mutating them.
require "webpush/vapid_key"
require "webpush/encryption"

module Webpush
  class VapidKey
    GROUP = OpenSSL::PKey::EC::Group.new("prime256v1")

    def self.from_keys(public_key, private_key)
      new(public_key: public_key, private_key: private_key)
    end

    def initialize(public_key: nil, private_key: nil)
      @curve =
        if public_key && private_key
          build_ec_key(to_big_num(public_key), to_big_num(private_key))
        else
          OpenSSL::PKey::EC.generate("prime256v1")
        end
    end

    private

    def build_ec_key(public_bn, private_bn)
      point = OpenSSL::PKey::EC::Point.new(GROUP, public_bn)
      asn1 = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer(1),
        OpenSSL::ASN1::OctetString(private_bn.to_s(2).rjust(32, "\x00")),
        OpenSSL::ASN1::ASN1Data.new([ OpenSSL::ASN1::ObjectId(GROUP.curve_name) ], 0, :CONTEXT_SPECIFIC),
        OpenSSL::ASN1::ASN1Data.new([ OpenSSL::ASN1::BitString(point.to_octet_string(:uncompressed)) ], 1, :CONTEXT_SPECIFIC)
      ])
      OpenSSL::PKey::EC.new(asn1.to_der)
    end

    def to_big_num(key)
      OpenSSL::BN.new(Webpush.decode64(key), 2)
    end
  end

  module Encryption
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = "prime256v1"
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)
      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)
      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = salt.to_s + [ rs ].pack("N*") + [ serverkey16bn.bytesize ].pack("C*") + serverkey16bn

      aes128gcmheader + ciphertext
    end
  end
end
