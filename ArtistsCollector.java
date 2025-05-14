class ArtistsCollector extends DataCollector{
    public Object get(Song music){
        return music.getArtist();
    }
}