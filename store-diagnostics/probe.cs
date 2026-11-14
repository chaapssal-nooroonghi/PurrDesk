using System;
using System.Runtime.InteropServices;
public static class ManifestProbe {
 [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] struct ACTCTX {
  public int cbSize; public uint flags; public string source; public ushort processorArchitecture; public ushort langId; public string assemblyDirectory; public IntPtr resourceName; public string applicationName; public IntPtr module;
 }
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateActCtx(ref ACTCTX a);
 [DllImport("kernel32.dll")] static extern void ReleaseActCtx(IntPtr h);
 [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr LoadLibraryEx(string path,IntPtr file,uint flags);
 [DllImport("kernel32.dll",SetLastError=true)] static extern IntPtr FindResource(IntPtr module,IntPtr name,IntPtr type);
 [DllImport("kernel32.dll")] static extern bool FreeLibrary(IntPtr module);
 public static string Probe(string path) {
  string result="Path="+path+"; ProcessBits="+(IntPtr.Size*8);
  IntPtr module=LoadLibraryEx(path,IntPtr.Zero,0x22);int error=Marshal.GetLastWin32Error();
  result+="; LoadLibraryEx="+(module!=IntPtr.Zero)+"; LoadError="+(module==IntPtr.Zero?error:0);
  if(module!=IntPtr.Zero){IntPtr r=FindResource(module,new IntPtr(1),new IntPtr(24));error=Marshal.GetLastWin32Error();result+="; ManifestResource="+(r!=IntPtr.Zero)+"; ResourceError="+(r==IntPtr.Zero?error:0);FreeLibrary(module);}
  ACTCTX a=new ACTCTX();a.cbSize=Marshal.SizeOf(typeof(ACTCTX));a.flags=8;a.source=path;a.resourceName=new IntPtr(1);
  IntPtr h=CreateActCtx(ref a);error=Marshal.GetLastWin32Error();bool ok=h!=new IntPtr(-1);result+="; CreateActCtx="+ok+"; ActivationError="+(ok?0:error);if(ok)ReleaseActCtx(h);return result;
 }
}
