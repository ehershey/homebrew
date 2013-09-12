require "formula"

class Frescobaldi < Formula
  homepage "http://frescobaldi.org/"
  url "https://lilykde.googlecode.com/files/frescobaldi-2.0.10.tar.gz"
  sha1 "17928c20fe3cda934cbff88872a1904a5b8994a3"

  option "without-launcher", "Don't build Mac .app launcher"
  option "without-lilypond", "Don't install Lilypond"

  depends_on :python2
  depends_on "portmidi" => :recommended
  depends_on "lilypond" => :recommended
  depends_on "platypus" => :build if build.with? "launcher"

  # python-poppler-qt4 dependencies
  depends_on "poppler" => "with-qt4"
  depends_on "pyqt"
  depends_on "pkg-config" => :build

  resource "python-poppler-qt4" do
    url "https://python-poppler-qt4.googlecode.com/files/python-poppler-qt4-0.16.3.tar.gz"
    sha1 "fe6aa650a1a917caeedd407ae0c428a5de9eefb8"
  end

  def install
    python do
      resource("python-poppler-qt4").stage do
        system "python", "setup.py", "build"
        system "python", "setup.py", "install"
      end
      system "python", "setup.py", "install", "--prefix=#{prefix}"
    end
    if build.with? "launcher"
      system "platypus", "-aFrescobaldi", "-oNone",
             bin/"frescobaldi", bin/"Frescobaldi.app"
    end
  end

  def caveats
    if build.with? "launcher"
      <<-EOS.undent
        To install the Mac OS X launcher application run:
          brew linkapps (to install in ~/Applications)
        or:
          ln -s #{bin}/Frescobaldi.app /Applications
      EOS
    end
  end
end
