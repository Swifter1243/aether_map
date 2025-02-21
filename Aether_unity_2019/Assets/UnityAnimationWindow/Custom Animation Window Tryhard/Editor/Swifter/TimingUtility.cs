namespace UnityAnimationWindow.Custom_Animation_Window_Tryhard.Editor.Swifter
{
    public class TimingUtility
    {
        public static float SecondsToBeat(float bpm, float seconds)
        {
            return bpm / 60 * seconds;
        }

        public static float BeatsToSeconds(float bpm, float beats)
        {
            return 60 / bpm * beats;
        }
    }
}