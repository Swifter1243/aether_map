using UnityEngine;
[System.Serializable]
public class ParticleSystemControlsState : PlayerPrefsSerializer
{
	[SerializeField] public bool m_isParticlePlaybackEnabled = false;

	protected override string PlayerPrefsKey => "ParticleSystemControlsState_";

	public override void Load()
	{
		m_isParticlePlaybackEnabled = LoadBool("isParticlePlaybackEnabled");
	}

	public override void Save()
	{
		SaveBool("isParticlePlaybackEnabled", m_isParticlePlaybackEnabled);
	}
}
