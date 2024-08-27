defmodule PictureWhisperWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use PictureWhisperWeb, :controller` and
  `use PictureWhisperWeb, :live_view`.
  """
  use PictureWhisperWeb, :html

  # import PictureWhisperWeb.CoreComponents

  embed_templates "layouts/*"

  def toast_class_fn(assigns) do
    [
      # base classes
      "bg-white group/toast z-100 pointer-events-auto relative w-full items-center justify-between origin-center overflow-hidden rounded-lg p-4 shadow-lg border col-start-1 col-end-1 row-start-1 row-end-2",
      # start hidden if javascript is enabled
      "[@media(scripting:enabled)]:opacity-0 [@media(scripting:enabled){[data-phx-main]_&}]:opacity-100",
      # used to hide the disconnected flashes
      if(assigns[:rest][:hidden] == true, do: "hidden", else: "flex"),
      # override styles per severity
      assigns[:kind] == :info &&
        "!bg-emerald-50 !text-emerald-800 ring-emerald-500 fill-cyan-900 ",
      assigns[:kind] == :success && "!bg-green-100 Ttext-green-800 ring-green fill-green-900",
      assigns[:kind] == :error && "!text-red-700 !bg-red-100 border-red-200",
      assigns[:kind] == :warn && "!text-amber-700 !bg-amber-100 border-amber-200"
    ]
  end

  def group_class_fn(assigns) do
    [
      # base classes
      "fixed z-50 max-h-screen w-full p-4 md:max-w-[420px] pointer-events-none grid origin-center",
      # classes to set container positioning
      assigns[:corner] == :bottom_left &&
        "items-end bottom-0 left-0 flex-col-reverse sm:top-auto",
      assigns[:corner] == :bottom_right &&
        "items-end bottom-0 right-0 flex-col-reverse sm:top-auto",
      assigns[:corner] == :top_left && "items-start top-0 left-0 flex-col sm:bottom-auto",
      assigns[:corner] == :top_right && "items-start top-0 right-0 flex-col sm:bottom-auto"
    ]
  end
end
