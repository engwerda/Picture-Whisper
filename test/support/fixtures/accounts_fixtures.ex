defmodule PictureWhisper.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PictureWhisper.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"
  def valid_user_name, do: "User #{System.unique_integer()}"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: valid_user_name(),
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def base_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> PictureWhisper.Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = base_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        PictureWhisper.Accounts.deliver_user_confirmation_instructions(user, url)
      end)

    {:ok, confirmed_user} = PictureWhisper.Accounts.confirm_user(token)
    confirmed_user
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    base_user_fixture(attrs)
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
