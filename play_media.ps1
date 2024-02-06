# https://stackoverflow.com/questions/25895428/how-to-play-mp3-with-powershell-simple

<#
   TypeName: System.Windows.Media.MediaPlayer

Name                    MemberType Definition
----                    ---------- ----------
BufferingEnded          Event      System.EventHandler BufferingEnded(System.Object, System.EventArgs)
BufferingStarted        Event      System.EventHandler BufferingStarted(System.Object, System.EventArgs)
Changed                 Event      System.EventHandler Changed(System.Object, System.EventArgs)
MediaEnded              Event      System.EventHandler MediaEnded(System.Object, System.EventArgs)
MediaFailed             Event      System.EventHandler`1[System.Windows.Media.ExceptionEventArgs] MediaFailed(System.Object, System.Windows.Media.ExceptionEventArgs)
MediaOpened             Event      System.EventHandler MediaOpened(System.Object, System.EventArgs)
ScriptCommand           Event      System.EventHandler`1[System.Windows.Media.MediaScriptCommandEventArgs] ScriptCommand(System.Object, System.Windows.Media.MediaScriptCommandEventArgs)     
ApplyAnimationClock     Method     void ApplyAnimationClock(System.Windows.DependencyProperty dp, System.Windows.Media.Animation.AnimationClock clock), void ApplyAnimationClock(System.Wind… 
BeginAnimation          Method     void BeginAnimation(System.Windows.DependencyProperty dp, System.Windows.Media.Animation.AnimationTimeline animation), void BeginAnimation(System.Windows… 
CheckAccess             Method     bool CheckAccess()
ClearValue              Method     void ClearValue(System.Windows.DependencyProperty dp), void ClearValue(System.Windows.DependencyPropertyKey key)
Clone                   Method     System.Windows.Media.Animation.Animatable Clone()
CloneCurrentValue       Method     System.Windows.Freezable CloneCurrentValue()
Close                   Method     void Close()
CoerceValue             Method     void CoerceValue(System.Windows.DependencyProperty dp)
Equals                  Method     bool Equals(System.Object obj)
Freeze                  Method     void Freeze()
GetAnimationBaseValue   Method     System.Object GetAnimationBaseValue(System.Windows.DependencyProperty dp), System.Object IAnimatable.GetAnimationBaseValue(System.Windows.DependencyPrope… 
GetAsFrozen             Method     System.Windows.Freezable GetAsFrozen()
GetCurrentValueAsFrozen Method     System.Windows.Freezable GetCurrentValueAsFrozen()
GetHashCode             Method     int GetHashCode()
GetLocalValueEnumerator Method     System.Windows.LocalValueEnumerator GetLocalValueEnumerator()
GetType                 Method     type GetType()
GetValue                Method     System.Object GetValue(System.Windows.DependencyProperty dp)
InvalidateProperty      Method     void InvalidateProperty(System.Windows.DependencyProperty dp)
Open                    Method     void Open(uri source)
Pause                   Method     void Pause()
Play                    Method     void Play()
ReadLocalValue          Method     System.Object ReadLocalValue(System.Windows.DependencyProperty dp)
SetCurrentValue         Method     void SetCurrentValue(System.Windows.DependencyProperty dp, System.Object value)
SetValue                Method     void SetValue(System.Windows.DependencyProperty dp, System.Object value), void SetValue(System.Windows.DependencyPropertyKey key, System.Object value)     
Stop                    Method     void Stop()
ToString                Method     string ToString()
VerifyAccess            Method     void VerifyAccess()
Balance                 Property   double Balance {get;set;}
BufferingProgress       Property   double BufferingProgress {get;}
CanFreeze               Property   bool CanFreeze {get;}
CanPause                Property   bool CanPause {get;}
Clock                   Property   System.Windows.Media.MediaClock Clock {get;set;}
DependencyObjectType    Property   System.Windows.DependencyObjectType DependencyObjectType {get;}
Dispatcher              Property   System.Windows.Threading.Dispatcher Dispatcher {get;}
DownloadProgress        Property   double DownloadProgress {get;}
HasAnimatedProperties   Property   bool HasAnimatedProperties {get;}
HasAudio                Property   bool HasAudio {get;}
HasVideo                Property   bool HasVideo {get;}
IsBuffering             Property   bool IsBuffering {get;}
IsFrozen                Property   bool IsFrozen {get;}
IsMuted                 Property   bool IsMuted {get;set;}
IsSealed                Property   bool IsSealed {get;}
NaturalDuration         Property   System.Windows.Duration NaturalDuration {get;}
NaturalVideoHeight      Property   int NaturalVideoHeight {get;}
NaturalVideoWidth       Property   int NaturalVideoWidth {get;}
Position                Property   timespan Position {get;set;}
ScrubbingEnabled        Property   bool ScrubbingEnabled {get;set;}
Source                  Property   uri Source {get;}
SpeedRatio              Property   double SpeedRatio {get;set;}
Volume                  Property   double Volume {get;set;}
#>

# Play a single file
$file = Get-ChildItem -Name "*.mp3"


# Add-Type -AssemblyName presentationCore
# $mediaPlayer = New-Object System.Windows.Media.MediaPlayer
# $mediaPlayer.open([uri]$file.FullName)
# if ($mediaPlayer.HasAudio) {
#     Write-Host "Playing '$($file.BaseName)'"
#     $mediaPlayer.SpeedRatio = 1.5
#     $mediaPlayer.Play()
# } else {
#     Write-Host "no audio detected."
# }

& 'C:\Program Files\VideoLAN\VLC\vlc.exe' --qt-start-minimized --play-and-exit --qt-notification=0 --rate=1.5 $file
