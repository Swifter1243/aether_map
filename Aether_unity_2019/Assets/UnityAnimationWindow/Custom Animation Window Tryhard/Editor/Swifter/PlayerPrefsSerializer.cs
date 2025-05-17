using UnityEngine;

public abstract class PlayerPrefsSerializer
{
	public abstract void Load();
	public abstract void Save();

	protected abstract string PlayerPrefsKey { get; }

	protected bool LoadBool(string name, bool defaultValue = false)
	{
		int value = PlayerPrefs.GetInt(PlayerPrefsKey + name, defaultValue ? 1 : 0);
		return value == 1;
	}

	protected int LoadInt(string name, int defaultValue = 0)
	{
		return PlayerPrefs.GetInt(PlayerPrefsKey + name, defaultValue);
	}

	protected string LoadString(string name, string defaultValue = null)
	{
		return PlayerPrefs.GetString(PlayerPrefsKey + name, defaultValue);
	}

	protected float LoadFloat(string name, float defaultValue = 0)
	{
		return PlayerPrefs.GetFloat(PlayerPrefsKey + name, defaultValue);
	}

	protected Color LoadColor(string name, Color defaultValue = default)
	{
		float r = LoadFloat(name + "_r", defaultValue.r);
		float g = LoadFloat(name + "_g", defaultValue.g);
		float b = LoadFloat(name + "_b", defaultValue.b);
		float a = LoadFloat(name + "_a", defaultValue.a);
		return new Color(r, g, b, a);
	}

	protected void SaveBool(string name, bool value)
	{
		PlayerPrefs.SetInt(PlayerPrefsKey + name, value ? 1 : 0);
	}

	protected void SaveInt(string name, int value)
	{
		PlayerPrefs.SetInt(PlayerPrefsKey + name, value);
	}

	protected void SaveString(string name, string value)
	{
		PlayerPrefs.SetString(PlayerPrefsKey + name, value);
	}

	protected void SaveFloat(string name, float value)
	{
		PlayerPrefs.SetFloat(PlayerPrefsKey + name, value);
	}

	protected void SaveColor(string name, Color value)
	{
		SaveFloat(name + "_r", value.r);
		SaveFloat(name + "_g", value.g);
		SaveFloat(name + "_b", value.b);
		SaveFloat(name + "_a", value.a);
	}
}
